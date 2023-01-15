output "db_host" {
  # we will get db instance address in the console, to check if evrything works good.
  value = aws_db_instance.main.address
}

output "bastion_host" {
  # this hostname will allow sysadmins to connect to aws resources specially postgres db etc
  value = aws_instance.bastion.public_dns
}

output "endpoint_api" {
  # address of the load balancer
  # value = aws_lb.api.dns_name

  # address of the domain name registered in route53
  value = aws_route53_record.app.fqdn
}