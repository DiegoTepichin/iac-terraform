resource "aws_lb" "this" {
  # checkov:skip=CKV_AWS_91:Access logs need a dedicated S3 bucket; out of scope for this reference.
  # checkov:skip=CKV2_AWS_28:WAF is out of scope for this reference (see README roadmap).
  # checkov:skip=CKV2_AWS_20:No domain or ACM certificate in scope, so there is no HTTPS listener to redirect to.
  # checkov:skip=CKV_AWS_150:Deletion protection is set per environment through var.enable_deletion_protection.
  name               = "${local.name_prefix}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  drop_invalid_header_fields = true
  enable_deletion_protection = var.enable_deletion_protection

  tags = {
    Name = "${local.name_prefix}-alb"
  }
}

resource "aws_lb_target_group" "app" {
  # checkov:skip=CKV_AWS_378:ALB-to-instance traffic stays inside the VPC on private subnets.
  name                 = "${local.name_prefix}-app"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    path                = "/"
    matcher             = "200"
    interval            = 15
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  # checkov:skip=CKV_AWS_2:No domain or ACM certificate in scope, so the listener is HTTP only (see README roadmap).
  # checkov:skip=CKV_AWS_103:Same as above: TLS policy only applies to an HTTPS listener.
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
