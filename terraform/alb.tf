resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP inbound"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "app_lb" {
  name               = "php-aws-alb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  security_groups = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "app_tg" {
  name     = "php-aws-tg"
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_ecs_service" "php_service" {
  name            = "php-aws-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.php_app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    assign_public_ip = true
    security_groups = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "php-aws-app"
    container_port   = 80
  }
}