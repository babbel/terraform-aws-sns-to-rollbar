# SNS topic (forwards messages to SQS queue)

resource "aws_sns_topic" "this" {
  name = var.name
  tags = var.tags
}

resource "aws_sns_topic_subscription" "sqs-queue" {
  topic_arn = aws_sns_topic.this.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.this.arn
}

# SQS queue

resource "aws_sqs_queue" "this" {
  name = var.name
  tags = var.tags
}

data "aws_iam_policy_document" "sqs-queue-consume" {
  statement {
    actions = [
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
    ]

    resources = [aws_sqs_queue.this.arn]
  }
}

resource "aws_sqs_queue_policy" "this" {
  queue_url = aws_sqs_queue.this.url
  policy    = data.aws_iam_policy_document.sqs-queue.json
}

data "aws_iam_policy_document" "sqs-queue" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.this.arn]

    condition {
      variable = "aws:SourceArn"
      test     = "ArnEquals"
      values   = [aws_sns_topic.this.arn]
    }
  }
}

# EventBridge Pipe (pipes messages from SQS queue to Step Function)

resource "aws_pipes_pipe" "this" {
  name     = var.name
  role_arn = aws_iam_role.pipes-pipe.arn

  source = aws_sqs_queue.this.arn

  target = aws_sfn_state_machine.this.arn

  target_parameters {
    input_template = <<EOF
      { "message": <$.body.Message> }
    EOF

    step_function_state_machine_parameters {
      invocation_type = "FIRE_AND_FORGET"
    }
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy.pipes-pipe-sqs-queue-consume,
    aws_iam_role_policy.pipes-pipe-sfn-state-machine-start-execution,
  ]
}

resource "aws_iam_role" "pipes-pipe" {
  name               = "pipes-${var.name}"
  assume_role_policy = data.aws_iam_policy_document.pipes-assume-role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "pipes-assume-role" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["pipes.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}
resource "aws_iam_role_policy" "pipes-pipe-sqs-queue-consume" {
  role   = aws_iam_role.pipes-pipe.name
  name   = "sqs-queue-consume"
  policy = data.aws_iam_policy_document.sqs-queue-consume.json
}

resource "aws_iam_role_policy" "pipes-pipe-sfn-state-machine-start-execution" {
  role   = aws_iam_role.pipes-pipe.name
  name   = "sfn-state-machine-start-execution"
  policy = data.aws_iam_policy_document.sfn-state-machine-start-execution.json
}

# Step Function (invokes Rollbar API)

resource "aws_sfn_state_machine" "this" {
  name     = var.name
  role_arn = aws_iam_role.sfn-state-machine.arn

  definition = jsonencode({
    StartAt = "PostItems"

    States = {
      PostItems = {
        Type = "Map"

        ItemProcessor = {
          StartAt = var.json_key != "-" ? "IsJSON" : "DontParseJSON"

          States = merge(
            (
              var.json_key != "-" ?
              {
                IsJSON = {
                  Type = "Choice"

                  Choices = [
                    {
                      Variable      = "$.message"
                      StringMatches = "{*}"
                      Next          = "ParseJSON"
                    },
                  ]

                  Default = "DontParseJSON"
                }

                ParseJSON = {
                  Type = "Pass"

                  Parameters = {
                    "message.$" = "States.StringToJson($.message)"
                  }

                  Next = "FindBody"
                }

                FindBody = {
                  Type = "Pass"

                  Parameters = {
                    "body.$" = "$.message['${var.json_key}']"
                  }
                  ResultPath = "$.overrides"

                  Next = "MergeBody"
                }

                MergeBody = {
                  Type = "Pass"

                  Parameters = {
                    "message.$" = "States.JsonMerge($.message, $.overrides, false)"
                  }

                  Next = "PostItem"
                }
              } :
              {}
            ),

            {

              DontParseJSON = {
                Type = "Pass"

                Parameters = {
                  "message" = {
                    "body.$" = "$.message"
                  }
                }

                Next = "PostItem"
              }

              PostItem = {
                Type = "Task"

                Resource = "arn:aws:states:::http:invoke"

                Parameters = {
                  Method      = "POST"
                  ApiEndpoint = "https://api.rollbar.com/api/1/item/"
                  Headers = {
                    "Accept"       = "application/json"
                    "Content-Type" = "application/json"
                  }
                  Authentication = {
                    ConnectionArn = aws_cloudwatch_event_connection.this.arn
                  }
                  RequestBody = {
                    data = {
                      environment = var.environment
                      level       = var.level
                      body = {
                        "message.$" = "$.message"
                      }
                    }
                  }
                }

                End = true
              }
            }
          )
        }

        End = true
      }
    }
  })

  tags = var.tags
}

data "aws_iam_policy_document" "sfn-state-machine-start-execution" {
  statement {
    actions   = ["states:StartExecution"]
    resources = [aws_sfn_state_machine.this.arn]
  }
}

resource "aws_iam_role" "sfn-state-machine" {
  name               = "step-function-${var.name}"
  assume_role_policy = data.aws_iam_policy_document.states.json
  tags               = var.tags
}

data "aws_iam_policy_document" "states" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "sfn-state-machine-invoke-http-endpoint" {
  role   = aws_iam_role.sfn-state-machine.name
  name   = "invoke-http-endpoint"
  policy = data.aws_iam_policy_document.invoke-http-endpoint.json
}

# Rollbar

resource "aws_cloudwatch_event_connection" "this" {
  name               = "${var.name}-rollbar"
  description        = "Posts items to Rollbar"
  authorization_type = "API_KEY"

  auth_parameters {
    api_key {
      key   = "X-Rollbar-Access-Token"
      value = var.rollbar_project_access_token.access_token
    }
  }
}

data "aws_iam_policy_document" "invoke-http-endpoint" {
  statement {
    actions = [
      "states:InvokeHTTPEndpoint",
    ]
    resources = ["*"]

    condition {
      variable = "states:HTTPMethod"
      test     = "StringEquals"
      values   = ["POST"]
    }

    condition {
      variable = "states:HTTPEndpoint"
      test     = "StringEquals"
      values   = ["https://api.rollbar.com/api/1/item/"]
    }
  }

  statement {
    actions = [
      "events:RetrieveConnectionCredentials",
    ]
    resources = [aws_cloudwatch_event_connection.this.arn]
  }

  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [aws_cloudwatch_event_connection.this.secret_arn]
  }
}
