data "aws_caller_identity" "current" {}

resource "aws_ecr_repository" "php_app" {
  name = "php-aws-app"
}

resource "aws_ecr_replication_configuration" "replication" {
  replication_configuration {
    rules {
      destinations {
        region      = "us-west-2"
        registry_id = data.aws_caller_identity.current.account_id
      }

      repository_filters {
        filter      = "php-aws-app"
        filter_type = "PREFIX_MATCH"
      }
    }
  }
}
