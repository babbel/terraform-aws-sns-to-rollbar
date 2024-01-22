output "sns_topic" {
  value = aws_sns_topic.this

  description = <<EOS
The SNS topic to which to publish the messages which shall be sent to Rollbar.
EOS
}
