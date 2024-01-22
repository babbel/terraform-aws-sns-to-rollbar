provider "aws" {
  region = "local"
}

module "athena" {
  source = "./.."

  name = "example"

  environment = "test"
  level = "debug"

  json_key = "message"

  rollbar_project_access_token = {
    access_token = "some-token"
  }

  tags = {
    app = "some-service"
    env = "production"
  }
}
