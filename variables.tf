variable "default_tags" {
  type    = map(string)
  default = {}

  description = <<EOS
Map of tags assigned to all AWS resources created by this module.
EOS
}

variable "environment" {
  type = string

  description = <<EOS
The environment to use in the Rollbar item.
EOS
}

variable "json_key" {
  type    = string
  default = "-"

  description = <<EOS
If the message is JSON, this is the key to use to extract the message used as Rollbar item title.
If the value is "-", the implementation will not attempt to parse the message as JSON.
EOS
}

variable "level" {
  type = string

  description = <<EOS
The level to use in the Rollbar item.
EOS
}

variable "name" {
  type = string

  description = <<EOS
The name used in all related AWS resources.
EOS
}

variable "pipes_pipe_iam_role_tags" {
  type    = map(string)
  default = {}

  description = <<EOS
Map of tags assigned to the IAM role created for the EventBridge Pipe created by this module.
EOS
}

variable "pipes_pipe_tags" {
  type    = map(string)
  default = {}

  description = <<EOS
Map of tags assigned to the EventBridge Pipe created by this module.
EOS
}

variable "rollbar_project_access_token" {
  type = object({
    access_token = string
  })

  description = <<EOS
The Rollbar project access token used to post items to Rollbar. It must the `post_server_item` scope.
EOS
}

variable "sfn_state_machine_iam_role_tags" {
  type    = map(string)
  default = {}

  description = <<EOS
Map of tags assigned to the IAM role created for the Step Functions state machine created by this module.
EOS
}

variable "sfn_state_machine_tags" {
  type    = map(string)
  default = {}

  description = <<EOS
Map of tags assigned to the Step Functions state machine created by this module.
EOS
}

variable "sns_topic_tags" {
  type    = map(string)
  default = {}

  description = <<EOS
Map of tags assigned to the SNS topic created by this module.
EOS
}

variable "sqs_queue_tags" {
  type    = map(string)
  default = {}

  description = <<EOS
Map of tags assigned to the SQS queue created by this module.
EOS
}
