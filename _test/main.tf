provider "aws" {
  region = "local"
}

module "sns-to-rollbar-with-json-key" {
  source = "./.."

  name = "example"

  json_key = "message"

  iam_role_permissions_boundary_name = "example-boundary"

  rollbar_project_access_token = {
    access_token = "some-token"
  }

  environment = "test"
  level       = "debug"

  default_tags = {
    app = "some-service"
    env = "test"
  }
}

module "sns-to-rollbar-without-json-key" {
  source = "./.."

  name = "example"

  rollbar_project_access_token = {
    access_token = "some-token"
  }

  environment = "test"
  level       = "debug"

  default_tags = {
    app = "some-service"
    env = "test"
  }
}
