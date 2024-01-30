resource "aws_ecr_repository" "fiap_pagamento" {
  name                 = "fiap-pagamento"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}


resource "aws_ecs_cluster" "fiap_pagamento" {
  name = "cluster-${var.app_name}"
  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }

  service_connect_defaults {
    namespace = var.ecs_namespace
  }

}


resource "aws_security_group" "cluster" {
  name        = "cluster-${var.app_name}-sg"
  description = "Security group for cluster ECS"
  vpc_id      = data.aws_vpc.cluster.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.balancer.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cluster-${var.app_name}-sg"
  }
}

resource "aws_ecs_task_definition" "fiap_pagamento" {
  family                   = "task-${var.app_name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = data.aws_iam_role.name.arn
  task_role_arn            = data.aws_iam_role.name.arn
  cpu                      = 1024
  memory                   = 2048
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  container_definitions = jsonencode([
    {
      name  = "service-fiap-pagamento"
      image = "${aws_ecr_repository.fiap_pagamento.repository_url}:0.0.1"
      portMappings = [
        {
          name          = "service-fiap-pagamento-8080-tcp"
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
          appProtocol   = "http"
        }

      ],
      environment = [
        {
          name  = "MYSQL_HOST"
          value = "${var.rds_host}"
        },
        {
          name  = "MYSQL_USERNAME"
          value = "${var.rds_username}"
        },
        {
          name  = "MYSQL_PASSWORD"
          value = "${var.rds_password}"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/task-${var.app_name}"
          "awslogs-region"        = "sa-east-1"
          "awslogs-stream-prefix" = "ecs"
          "awslogs-create-group"  = "true"
        }
      }
    }
    ]
  )

  tags = {
    Name = "task-${var.app_name}"
  }
}


resource "aws_ecs_service" "name" {
  name            = "service-${var.app_name}"
  cluster         = aws_ecs_cluster.fiap_pagamento.id
  task_definition = aws_ecs_task_definition.fiap_pagamento.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = [data.aws_subnet.clustera.id, data.aws_subnet.clusterb.id]
    security_groups  = [aws_security_group.cluster.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.fiap_pagamento.arn
    container_name   = "service-fiap-pagamento"
    container_port   = 8080
  }
  tags = {
    Name = "service-${var.app_name}"
  }

  depends_on = [aws_lb.fiap_pagamento]

}
