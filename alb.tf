resource "aws_lb" "fiap_pagamento" {
  name                             = "lb-${var.app_name}"
  load_balancer_type               = "application"
  internal                         = true
  security_groups                  = [aws_security_group.balancer.id]
  subnets                          = [data.aws_subnet.clustera.id, data.aws_subnet.clusterb.id]
  idle_timeout                     = 60
  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true
  enable_http2                     = true
  tags = {
    Name = "lb-${var.app_name}"
  }

}

resource "aws_lb_listener" "fiap_pagamento" {
  load_balancer_arn = aws_lb.fiap_pagamento.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fiap_pagamento.arn
  }
  depends_on = [aws_lb_target_group.fiap_pagamento]
}

resource "aws_lb_target_group" "fiap_pagamento" {
  name        = "tg-${var.app_name}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.cluster.id
  target_type = "ip"
  health_check {
    path                = "/api/v1/health-check"
    port                = 8080
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
  tags = {
    Name = "tg-${var.app_name}"
  }
}


resource "aws_security_group" "balancer" {
  name        = "alb-fiap-pagamento-sg"
  description = "Security group for balancer"
  vpc_id      = data.aws_vpc.cluster.id

  ingress {
    description      = "ingress port 80"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    security_groups  = []
    ipv6_cidr_blocks = []
    prefix_list_ids  = []

  }

  egress {
    description      = "egress all traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    security_groups  = []
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
  }

  tags = {
    Name = "alb-${var.app_name}-sg"
  }

}
