variable "root_domain_name" {
  type        = string
  description = "The name of the domain to delegate a subdomain for, or an empty string if none should be created."
}

variable "subdomain_prefix" {
  type        = string
  description = "The name of the subdomain to create, or an empty string if none should be created."
}

locals {
  subdomain_name = var.root_domain_name == "" ? "" : "${var.subdomain_prefix}.${data.aws_route53_zone.root[0].name}"
}

resource "aws_route53_zone" "subdomain" {
  count = var.root_domain_name == "" ? 0 : 1
  name  = "${var.subdomain_prefix}.${data.aws_route53_zone.root[0].name}"
}

resource "aws_route53_record" "ns" {
  count   = var.root_domain_name == "" ? 0 : 1
  name    = aws_route53_zone.subdomain[0].name
  records = aws_route53_zone.subdomain[0].name_servers
  ttl     = "3600"
  type    = "NS"
  zone_id = data.aws_route53_zone.root[0].zone_id
}

data "aws_route53_zone" "root" {
  count = var.root_domain_name == "" ? 0 : 1
  name  = var.root_domain_name
}

output "full_subdomain" {
  value = var.root_domain_name == "" ? "" : local.subdomain_name
}

output "subdomain_zone_id" {
  value = var.root_domain_name == "" ? "" : aws_route53_zone.subdomain[0].zone_id
}
