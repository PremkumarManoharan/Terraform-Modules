
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_launch_configuration" "instance" {

    image_id = var.ami
    instance_type = var.instance_type
    security_groups = [aws_security_group.instance.id]
    
    user_data = templatefile("${path.module}/user-data.sh", {
      server_port = local.server_port
      db_address = var.db_remote_address
      db_port = var.db_remote_port
      server_text = var.server_text
    })
    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_security_group" "instance" {
  name = "${var.cluster_name}-instance-sg"
}

resource "aws_security_group_rule" "allow_port_8080" {
  type = "ingress"
  security_group_id = aws_security_group.instance.id

  from_port   = local.server_port
  to_port     = local.server_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}


resource "aws_autoscaling_group" "alb_asg" {
  name = var.cluster_name
  launch_configuration = aws_launch_configuration.instance.name
  vpc_zone_identifier = data.aws_subnets.default.ids
  min_size = var.min_size
  max_size = var.max_size
  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
  tag {
    key = "Name"
    value = "${var.cluster_name}-alb-asg"
    propagate_at_launch = true
  }
  dynamic "tag" {
    for_each = var.custom_tags
    content {
      key = tag.key
      value = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  count = var.enable_autoscaling ? 1 : 0
  scheduled_action_name = "scale_out_during_business_hours"
  min_size = 2
  max_size = 10
  desired_capacity = 10
  recurrence = "0 9 * * *"

  autoscaling_group_name = aws_autoscaling_group.alb_asg.name
}

resource "aws_autoscaling_schedule" "scale_in_at_off_business_hours" {
  count = var.enable_autoscaling ? 1 : 0
  scheduled_action_name = "scale_in_at_off_business_hours"
  min_size = 2
  max_size = 10
  desired_capacity = 2
  recurrence = "0 17 * * *"

  autoscaling_group_name = aws_autoscaling_group.alb_asg.name
  
}

resource "aws_lb" "alb" {
  name = "${var.cluster_name}-alb"
  load_balancer_type = "application"
  subnets = data.aws_subnets.default.ids
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port = local.http_port
  protocol = "HTTP"
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = 404
    }
  }
}

resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb-sg"
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type = "egress"
  security_group_id = aws_security_group.alb.id

    from_port = local.any_port
    to_port = local.any_port
    protocol = local.any_protocol
    cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type = "ingress"
  security_group_id = aws_security_group.alb.id

    from_port = local.any_port
    to_port = local.any_port
    protocol = local.any_protocol
    cidr_blocks = local.all_ips
}

resource "aws_lb_target_group" "asg" {
  name = "${var.cluster_name}-alb-tg"
  port = local.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

//comment