/*
 * # Terraform module alb
 * 
 * The module creates and configures Application Load Balancer for a deployment.
 * It sets up a security group, HTTP and HTTPS listeners, and a default target group for the load balancer.
 * if the hosted zone ID and domain name are provided, the module also creates Route 53 records for the load balancer.
 * The load balancer is configured to redirect HTTP ports to HTTPS.
 * The security group Id and ARN of the load balancer are stored in SSM Parameter Store.
 */

# Copyright 2025 Esri
#
# Licensed under the Apache License Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# EC2 security group for Application Load Balancer
resource "aws_security_group" "arcgis_alb" {
  name        = "${var.deployment_id}-alb"
  description = "Allow inbound traffic to load balancer ports"
  vpc_id      = var.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.deployment_id}-alb"
  }
}

resource "aws_security_group_rule" "allow_http" {
  count             = length(var.http_ports)
  description       = "Allow client access to port ${var.http_ports[count.index]}"
  type              = "ingress"
  from_port         = var.http_ports[count.index]
  to_port           = var.http_ports[count.index]
  protocol          = "tcp"
  cidr_blocks       = var.client_cidr_blocks
  security_group_id = aws_security_group.arcgis_alb.id
}

resource "aws_security_group_rule" "allow_https" {
  count             = length(var.https_ports)
  description       = "Allow client access to port ${var.https_ports[count.index]}"
  type              = "ingress"
  from_port         = var.https_ports[count.index]
  to_port           = var.https_ports[count.index]
  protocol          = "tcp"
  cidr_blocks       = var.client_cidr_blocks
  security_group_id = aws_security_group.arcgis_alb.id
}

# Application Load Balancer (ALB)
resource "aws_lb" "alb" {
  name               = var.deployment_id
  internal           = var.internal_load_balancer
  load_balancer_type = "application"
  security_groups    = [aws_security_group.arcgis_alb.id]

  subnets = var.subnets

  drop_invalid_header_fields = true
}

# Default target group
resource "aws_lb_target_group" "default" {
  name     = "${var.deployment_id}-default"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = var.vpc_id
}

# Redirect HTTP listeners to corresponding HTTPS listeners
resource "aws_lb_listener" "http" {
  count = length(var.http_ports)
  load_balancer_arn = aws_lb.alb.arn
  port              = var.http_ports[count.index]
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = var.https_ports[count.index]
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS listeners
resource "aws_lb_listener" "https" {
  count = length(var.https_ports)
  load_balancer_arn = aws_lb.alb.arn
  port              = var.https_ports[count.index]
  protocol          = "HTTPS"
  certificate_arn   = var.ssl_certificate_arn
  ssl_policy        = var.ssl_policy

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default.arn
  }
}

# Create Route 53 record for the Application Load Balancer 
# if the hosted zone ID and domain name are provided.
resource "aws_route53_record" "arcgis_server" {
  count = var.hosted_zone_id != null && var.deployment_fqdn != null ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = "${var.deployment_fqdn}."
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.alb.dns_name]
}

resource "aws_ssm_parameter" "alb_security_group_id" {
  name        = "/arcgis/${var.site_id}/${var.deployment_id}/alb/security-group-id"
  type        = "String"
  value       = aws_security_group.arcgis_alb.id
  description = "Security group Id of the deployment's ALB"
}

resource "aws_ssm_parameter" "alb_arn" {
  name        = "/arcgis/${var.site_id}/${var.deployment_id}/alb/arn"
  type        = "String"
  value       = aws_lb.alb.arn
  description = "ARN of the deployment's ALB"
}
