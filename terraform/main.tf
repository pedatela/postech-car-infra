locals {
  tags             = { Project = var.project_name }
  application_name = "${var.project_name}-app"
}

resource "aws_ecr_repository" "app" {
  name                 = local.application_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.tags
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = local.tags
}

resource "aws_subnet" "public" {
  for_each = {
    a = "10.0.1.0/24"
    b = "10.0.2.0/24"
  }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = "${var.aws_region}${each.key}"
  map_public_ip_on_launch = true
  tags                    = merge(local.tags, { Name = "public-${each.key}" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = local.tags
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = local.tags
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb"
  description = "ALB ingress"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_security_group" "app_service" {
  name        = "${local.application_name}-svc"
  description = "App tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol        = "tcp"
    from_port       = var.app_container_port
    to_port         = var.app_container_port
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_lb" "app" {
  name               = "${local.application_name}-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = values(aws_subnet.public)[*].id
  tags               = local.tags
}

resource "aws_lb_target_group" "app" {
  name        = "${local.application_name}-tg"
  port        = var.app_container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    path                = "/"
  }

  tags = local.tags
}

resource "aws_lb_listener" "app_http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
  tags = local.tags
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${local.application_name}"
  retention_in_days = 7
  tags              = local.tags
}

resource "aws_iam_role" "task_execution" {
  name = "${var.project_name}-ecs-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution_role" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  name = "${var.project_name}-ecs-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${local.application_name}-task"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = local.application_name
      image     = var.app_container_image != "" ? var.app_container_image : "${aws_ecr_repository.app.repository_url}:latest"
      essential = true
      portMappings = [{
        containerPort = var.app_container_port
        hostPort      = var.app_container_port
        protocol      = "tcp"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = local.application_name
        }
      }
      environment = [
        {
          name  = "PORT"
          value = tostring(var.app_container_port)
        },
        {
          name  = "COGNITO_REGION"
          value = var.aws_region
        },
        {
          name  = "COGNITO_USER_POOL_ID"
          value = aws_cognito_user_pool.this.id
        },
        {
          name  = "COGNITO_CLIENT_ID"
          value = aws_cognito_user_pool_client.this.id
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "app" {
  name            = "${local.application_name}-svc"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.app_desired_count
  launch_type     = "FARGATE"
  depends_on      = [aws_lb_listener.app_http]

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = values(aws_subnet.public)[*].id
    security_groups  = [aws_security_group.app_service.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = local.application_name
    container_port   = var.app_container_port
  }

  tags = local.tags
}

resource "random_string" "cognito_domain_suffix" {
  length  = 5
  upper   = false
  special = false
}

resource "aws_cognito_user_pool" "this" {
  name = "${var.project_name}-users"

  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  tags = local.tags
}

resource "aws_cognito_user_pool_client" "this" {
  name         = "${var.project_name}-app-client"
  user_pool_id = aws_cognito_user_pool.this.id

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  supported_identity_providers         = ["COGNITO"]
  prevent_user_existence_errors        = "ENABLED"

  callback_urls = var.cognito_callback_urls
  logout_urls   = var.cognito_logout_urls

  generate_secret = false
}

resource "aws_cognito_user_pool_domain" "this" {
  domain       = "${var.project_name}-${random_string.cognito_domain_suffix.result}"
  user_pool_id = aws_cognito_user_pool.this.id
}
