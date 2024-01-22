variable "environment" {
  type = string

  description = <<EOS
The environment to use in the Rollbar item.
EOS
}

variable "json_key" {
  type = string

  description = <<EOS
If the message is JSON, this is the key to use to extract the message used as Rollbar item title.
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

variable "rollbar_project_access_token" {
  type = object({
    access_token = string
  })

  description = <<EOS
The Rollbar project access token used to post items to Rollbar. It must the `post_server_item` scope.
EOS
}

variable "tags" {
  type = map(string)
  default = {}

  description = <<EOS
Tags to apply to all AWS resources.
EOS
}
