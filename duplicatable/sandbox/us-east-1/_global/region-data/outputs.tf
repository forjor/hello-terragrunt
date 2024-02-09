output "azs" {
  value = slice(data.aws_availability_zones.available.names, 0, 3)
}

output "fluent_ssm_param" {
  value = nonsensitive(data.aws_ssm_parameter.fluentbit.value)
}
