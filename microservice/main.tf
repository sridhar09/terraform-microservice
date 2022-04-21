
resource "aws_autoscaling_group" "microservice" {
  name                 = aws_launch_configuration.microservice.name
  launch_configuration = aws_launch_configuration.microservice.name

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.min_size
  min_elb_capacity = var.min_size

  vpc_zone_identifier = data.aws_subnet_ids.default.ids

  health_check_type         = "ELB"
  health_check_grace_period = 30
  target_group_arns         = aws_alb_target_group.web_servers.*.arn

  tag {
    key                 = "Name"
    value               = "${var.student_alias}-${var.name}"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = ["aws_alb_listener.http"]
}


resource "aws_launch_configuration" "microservice" {
  name          = "${var.student_alias}-${var.name}"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  user_data     = data.template_file.user_data.rendered

  key_name        = var.key_name
  security_groups = aws_security_group.web_server.*.id

  lifecycle {
    create_before_destroy = true
  }
}


data "template_file" "user_data" {
  template = var.user_data_script

  vars = {
    server_text      = var.server_text
    server_http_port = var.server_http_port
    backend_url      = var.backend_url
  }
}


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "image-type"
    values = ["machine"]
  }

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }
}


resource "aws_security_group" "web_server" {
  name   = "${var.student_alias}-${var.name}"
  vpc_id = data.aws_vpc.default.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "web_server_allow_http_inbound" {
  type              = "ingress"
  from_port         = var.server_http_port
  to_port           = var.server_http_port
  protocol          = "tcp"
  security_group_id = aws_security_group.web_server.id

  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "web_server_allow_ssh_inbound" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.web_server.id

  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "web_server_allow_all_outbound" {
  type              = "egress"
  from_port         = 1
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.web_server.id
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_alb" "web_servers" {
  name            = "${var.student_alias}-${var.name}"
  security_groups = aws_security_group.alb.*.id
  subnets         = data.aws_subnet_ids.default.ids
  internal        = var.is_internal_alb

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_alb.web_servers.arn
  port              = var.alb_http_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.web_servers.arn
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_alb_target_group" "web_servers" {
  name     = "${var.student_alias}-${var.name}"
  port     = var.server_http_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  deregistration_delay = 10

  health_check {
    path                = "/"
    interval            = 15
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_alb_listener_rule" "send_all_to_web_servers" {
  listener_arn = aws_alb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.web_servers.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}


resource "aws_security_group" "alb" {
  name   = "${var.student_alias}-${var.name}-alb"
  vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group_rule" "alb_allow_http_inbound" {
  type              = "ingress"
  from_port         = var.alb_http_port
  to_port           = var.alb_http_port
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = ["0.0.0.0/0"]
}


data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}