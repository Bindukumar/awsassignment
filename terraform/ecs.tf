resource "aws_ecs_cluster" "main" {
  name = "php-aws-cluster"
}

resource "aws_ecs_task_definition" "php_app" {
  family                   = "php-aws-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "php-aws-app"
      image     = var.ecr_image_url
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}