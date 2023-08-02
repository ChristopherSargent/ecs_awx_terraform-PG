provider "aws" {
  region = var.selected_region
  # user should have the administration policy or policy as per the lpp principle
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
#  token = var.aws_session_token
}

