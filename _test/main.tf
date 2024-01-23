provider "aws" {
  region = "local"
}

module "sns-to-rollbar" {
  source = "./.."

  name = "example"

  json_key = "message"

  rollbar_project_access_token = {
    access_token = "some-token"
  }

  environment = "test"
  level       = "debug"

  tags = {
    app = "some-service"
    env = "test"
  }
}
