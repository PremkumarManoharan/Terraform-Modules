output "alb_dns_name" {
  value = aws_lb.alb.dns_name
  description = "The is the DNS name for the load balancer"
}

output "asg_name" {
  value = aws_autoscaling_group.alb_asg.name
  description = "The name of the Auto Scaling Group"
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
  description = "The Id of th security group attached to the load balancer"
}