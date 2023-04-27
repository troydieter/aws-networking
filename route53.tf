resource "aws_route53_zone" "awsdnsm4lcom" {
  provider = aws.primary
  name     = "aws.contoso.io"

  vpc {
    vpc_id = aws_vpc.awsvpc.id
  }
}

resource "aws_route53_record" "awsdnsm4lcomweb" {
  provider = aws.primary
  zone_id  = aws_route53_zone.awsdnsm4lcom.zone_id
  name     = "web.aws.contoso.io"
  type     = "A"
  ttl      = "60"
  records = [
    aws_instance.awsec2a.private_ip,
    aws_instance.awsec2b.private_ip
  ]
}

resource "aws_route53_resolver_endpoint" "m4linbound" {
  provider  = aws.primary
  name      = "m4linbound-${random_id.rando_primary.hex}"
  direction = "INBOUND"

  security_group_ids = [aws_security_group.AWSSecurityGroup.id]

  ip_address {
    subnet_id = aws_subnet.micros4l-private-a.id
  }

  ip_address {
    subnet_id = aws_subnet.micros4l-private-b.id
  }

}

resource "aws_route53_resolver_endpoint" "m4loutbound" {
  provider  = aws.primary
  name      = "m4loutbound-${random_id.rando_primary.hex}"
  direction = "OUTBOUND"

  security_group_ids = [aws_security_group.AWSSecurityGroup.id]

  ip_address {
    subnet_id = aws_subnet.micros4l-private-a.id
  }

  ip_address {
    subnet_id = aws_subnet.micros4l-private-b.id
  }

}

resource "aws_route53_resolver_rule" "m4loutbound_fwd" {
  provider             = aws.primary
  domain_name          = "corp.contoso.io"
  name                 = "m4l-corpzone-${random_id.rando_primary.hex}"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.m4loutbound.id

  target_ip {
    ip = aws_instance.onpremdnsa.private_ip
  }

  target_ip {
    ip = aws_instance.onpremdnsb.private_ip
  }

}

resource "aws_route53_resolver_rule_association" "m4loutbound_fwd_rule" {
  provider         = aws.primary
  resolver_rule_id = aws_route53_resolver_rule.m4loutbound_fwd.id
  vpc_id           = aws_vpc.awsvpc.id
}
