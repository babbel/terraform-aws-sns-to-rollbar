# AWS SNS to Rollbar

Terraform module which allows posting SNS messages to Rollbar

## Usage

```tf
module "sns-to-rollbar" {
  source  = "babbel/sns-to-rollbar/aws"
  version = "~> 1.0"

  name = "example"

  json_key = "message"

  rollbar_project_access_token = {
    access_token = "some-token"
  }

  environment = "test"
  level      = "debug"
}
```
