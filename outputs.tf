output "sns_topic" {
  value = aws_sns_topic.sns_topic

  description = <<EOS
The SNS topic to which to publish the messages which shall be sent to Rollbar.
EOS
}
