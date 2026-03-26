variable "github_token" {
  type = string
}

# -----------------------------
# Artifact Buckets (East + West)
# -----------------------------

resource "aws_s3_bucket" "pipeline_bucket_east" {
  bucket = "pipeline-artifacts-473427586352-east"
}

resource "aws_s3_bucket" "pipeline_bucket_west" {
  bucket = "pipeline-artifacts-473427586352-west"
}

# -----------------------------
# CodePipeline
# -----------------------------

resource "aws_codepipeline" "php_pipeline" {
  name     = "php-aws-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  # MULTI-REGION ARTIFACT STORES
  artifact_stores = {
    "us-east-1" = {
      location = aws_s3_bucket.pipeline_bucket_east.bucket
      type     = "S3"
    }

    "us-west-2" = {
      location = aws_s3_bucket.pipeline_bucket_west.bucket
      type     = "S3"
    }
  }

  # -----------------------------
  # Source Stage (GitHub v1 for now)
  # -----------------------------
  stage {
    name = "Source"

    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = "<YOUR_GITHUB_USERNAME>"
        Repo       = "<YOUR_REPO_NAME>"
        Branch     = "main"
        OAuthToken = var.github_token
      }
    }
  }

  # -----------------------------
  # Build Stage
  # -----------------------------
  stage {
    name = "Build"

    action {
      name             = "Docker_Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.php_build.name
      }
    }
  }

  # -----------------------------
  # Deploy to Staging (us-east-1)
  # -----------------------------
  stage {
    name = "Deploy_Staging"

    action {
      name            = "Deploy_to_Staging"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"
      region          = "us-east-1"

      configuration = {
        ClusterName = aws_ecs_cluster.main.name
        ServiceName = aws_ecs_service.php_service.name
        FileName    = "imagedefinitions.json"
      }
    }
  }

  # -----------------------------
  # Manual Approval
  # -----------------------------
  stage {
    name = "Approval"

    action {
      name     = "Manual_Approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
    }
  }

  # -----------------------------
  # Deploy to Prod East (us-east-1)
  # -----------------------------
  stage {
    name = "Deploy_Prod_East"

    action {
      name            = "Deploy_to_Prod_East"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"
      region          = "us-east-1"

      configuration = {
        ClusterName = aws_ecs_cluster.main.name
        ServiceName = aws_ecs_service.php_service.name
        FileName    = "imagedefinitions.json"
      }
    }
  }

  # -----------------------------
  # Deploy to Prod West (us-west-2)
  # -----------------------------
  stage {
    name = "Deploy_Prod_West"

    action {
      name            = "Deploy_to_Prod_West"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"
      region          = "us-west-2"   # ✔ Correct region override

      configuration = {
        ClusterName = "php-aws-cluster"
        ServiceName = "php-aws-service"
        FileName    = "imagedefinitions.json"
      }
    }
  }
}
