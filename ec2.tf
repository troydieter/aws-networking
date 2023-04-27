resource "random_id" "rando_primary" {
  byte_length = 2
}

resource "random_id" "rando_secondary" {
  byte_length = 2
}

data "aws_ami" "amazon-linux-2" {
  provider    = aws.primary
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

data "aws_iam_instance_profile" "EC2profile" {
  provider = aws.primary
  name     = "EC2profile-${random_id.rando_primary.hex}"
  depends_on = [
    aws_iam_instance_profile.EC2profile
  ]
}

data "aws_route53_resolver_endpoint" "inbound" {
  filter {
    name = aws_route53_resolver_endpoint.m4linbound.name
  }
  depends_on = [
    aws_route53_resolver_endpoint.m4linbound
  ]
}

resource "aws_security_group" "AWSSecurityGroup" {
  provider    = aws.primary
  name        = "AWSSecurityGroup-${random_id.rando_primary.hex}"
  description = "Enable SSH and DNS"
  vpc_id      = aws_vpc.awsvpc.id

  ingress {
    description = "Allow SSH IPv4 IN"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP IPv4 IN"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow HTTPS IPv4 OUT - SSM"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS IPv4 IN - SSM"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow tcp DNS IN"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow tcp DNS OUT"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow udp DNS IN"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow udp DNS OUT"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "AWSDefaultInstanceSecurityGroupSelfReferenceRule" {
  provider          = aws.primary
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.AWSSecurityGroup.id
}

resource "aws_instance" "awsec2a" {
  provider = aws.primary
  depends_on = [
    aws_vpc_endpoint.awsssminterfaceendpoint,
    aws_vpc_endpoint.awsssmec2messagesinterfaceendpoint,
    aws_vpc_endpoint.awsssmmessagesinterfaceendpoint
  ]
  ami                    = data.aws_ami.amazon-linux-2.id
  instance_type          = "t2.micro"
  iam_instance_profile   = data.aws_iam_instance_profile.EC2profile.name
  subnet_id              = aws_subnet.micros4l-private-a.id
  vpc_security_group_ids = [aws_security_group.AWSSecurityGroup.id]
  tags = {
    Name = "micros4l-awsec2a-${random_id.rando_primary.hex}"
  }
  user_data = <<EOF
  #!/bin/bash -xe
  cd /tmp 
  sudo yum install -y https://s3.${var.region_primary}.amazonaws.com/amazon-ssm-${var.region_primary}/latest/linux_amd64/amazon-ssm-agent.rpm 
  sudo systemctl enable amazon-ssm-agent 
  sudo systemctl start amazon-ssm-agent

EOF
}

resource "aws_instance" "awsec2b" {
  provider = aws.primary
  depends_on = [
    aws_vpc_endpoint.awsssminterfaceendpoint,
    aws_vpc_endpoint.awsssmec2messagesinterfaceendpoint,
    aws_vpc_endpoint.awsssmmessagesinterfaceendpoint
  ]
  ami                    = data.aws_ami.amazon-linux-2.id
  instance_type          = "t2.micro"
  iam_instance_profile   = data.aws_iam_instance_profile.EC2profile.name
  subnet_id              = aws_subnet.micros4l-private-b.id
  vpc_security_group_ids = [aws_security_group.AWSSecurityGroup.id]
  tags = {
    Name = "micros4l-awsec2b-${random_id.rando_primary.hex}"
  }
  user_data = <<EOF
  #!/bin/bash -xe
  cd /tmp 
  sudo yum install -y https://s3.${var.region_primary}.amazonaws.com/amazon-ssm-${var.region_primary}/latest/linux_amd64/amazon-ssm-agent.rpm
  sudo systemctl enable amazon-ssm-agent 
  sudo systemctl start amazon-ssm-agent

EOF  
}

################################################
# SECONDARY REGION
################################################

data "aws_ami" "amazon-linux-2_secondary" {
  provider    = aws.secondary
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

data "aws_iam_instance_profile" "EC2profile_secondary" {
  provider = aws.secondary
  name     = "EC2profile-${random_id.rando_primary.hex}"
  depends_on = [
    aws_iam_instance_profile.EC2profile
  ]
}

resource "aws_security_group" "OnPremSecurityGroup" {
  provider    = aws.secondary
  name        = "OnPremSecurityGroup-${random_id.rando_secondary.hex}"
  description = "Enable SSH and DNS"
  vpc_id      = aws_vpc.onpremvpc.id

  ingress {
    description = "Allow SSH IPv4 IN"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP IPv4 IN"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow HTTPS IPv4 OUT - SSM"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS IPv4 IN - SSM"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow tcp DNS IN"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow tcp DNS OUT"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow udp DNS IN"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow udp DNS OUT"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "OnPremDefaultInstanceSecurityGroupSelfReferenceRule" {
  provider          = aws.secondary
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.OnPremSecurityGroup.id
}

resource "aws_instance" "onpremdnsa" {
  provider = aws.secondary
  depends_on = [
    aws_vpc_endpoint.onpremssminterfaceendpoint,
    aws_vpc_endpoint.onpremssmec2messagesinterfaceendpoint,
    aws_vpc_endpoint.onpremssmmessagesinterfaceendpoint
  ]
  ami                    = data.aws_ami.amazon-linux-2_secondary.id
  instance_type          = "t2.micro"
  iam_instance_profile   = data.aws_iam_instance_profile.EC2profile_secondary.name
  subnet_id              = aws_subnet.onprem-private-a.id
  vpc_security_group_ids = [aws_security_group.OnPremSecurityGroup.id]
  tags = {
    Name = "micros4l-onpremdnsa-${random_id.rando_secondary.hex}"
  }
  user_data = <<-EOT
  #!/bin/bash -xe
  yum update -y
  yum install bind bind-utils -y
  cat <<EOF > /etc/named.conf
  options {
    directory	"/var/named";
    dump-file	"/var/named/data/cache_dump.db";
    statistics-file "/var/named/data/named_stats.txt";
    memstatistics-file "/var/named/data/named_mem_stats.txt";
    allow-query { any; };
    allow-transfer     { localhost; ${aws_instance.onpremdnsb.private_ip}; };
    recursion yes;
    forward first;
    forwarders {
      192.168.10.2;
    };
    dnssec-enable yes;
    dnssec-validation yes;
    dnssec-lookaside auto;
    /* Path to ISC DLV key */
    bindkeys-file "/etc/named.iscdlv.key";
    managed-keys-directory "/var/named/dynamic";
  };
  zone "corp.contoso.io" IN {
      type master;
      file "corp.contoso.io.zone";
      allow-update { none; };
  };
  zone "aws.contoso.io" { 
  type forward; 
  forward only;
  forwarders { ${data.aws_route53_resolver_endpoint.inbound.ip_addresses[0]}; ${data.aws_route53_resolver_endpoint.inbound.ip_addresses[1]}; }; 
  };
  EOF
  cat <<EOF > /var/named/corp.contoso.io.zone
  \$TTL 86400
  @   IN  SOA     ns1.mydomain.com. root.mydomain.com. (
          2013042201  ;Serial
          3600        ;Refresh
          1800        ;Retry
          604800      ;Expire
          86400       ;Minimum TTL
  )
  ; Specify our two nameservers
      IN	NS		dnsA.corp.contoso.io.
      IN	NS		dnsB.corp.contoso.io.
  ; Resolve nameserver hostnames to IP, replace with your two droplet IP addresses.
  dnsA		IN	A		1.1.1.1
  dnsB	  IN	A		8.8.8.8
  
  ; Define hostname -> IP pairs which you wish to resolve
  @		  IN	A		${aws_instance.onpremapp.private_ip}
  app		IN	A	  ${aws_instance.onpremapp.private_ip}
  EOF
  service named restart
  chkconfig named on
  cd /tmp 
  sudo yum install -y https://s3.${var.region_secondary}.amazonaws.com/amazon-ssm-${var.region_secondary}/latest/linux_amd64/amazon-ssm-agent.rpm 
  sudo systemctl enable amazon-ssm-agent 
  sudo systemctl start amazon-ssm-agent
    
EOT
}

resource "aws_instance" "onpremdnsb" {
  provider = aws.secondary
  depends_on = [
    aws_vpc_endpoint.onpremssminterfaceendpoint,
    aws_vpc_endpoint.onpremssmec2messagesinterfaceendpoint,
    aws_vpc_endpoint.onpremssmmessagesinterfaceendpoint
  ]
  ami                    = data.aws_ami.amazon-linux-2_secondary.id
  instance_type          = "t2.micro"
  iam_instance_profile   = data.aws_iam_instance_profile.EC2profile_secondary.name
  subnet_id              = aws_subnet.onprem-private-b.id
  vpc_security_group_ids = [aws_security_group.OnPremSecurityGroup.id]
  tags = {
    Name = "micros4l-onpremdnsb-${random_id.rando_secondary.hex}"
  }
  user_data = <<-EOT
  #!/bin/bash -xe
  yum update -y
  yum install bind bind-utils -y
  cat <<EOF > /etc/named.conf
  options {
    directory	"/var/named";
    dump-file	"/var/named/data/cache_dump.db";
    statistics-file "/var/named/data/named_stats.txt";
    memstatistics-file "/var/named/data/named_mem_stats.txt";
    allow-query { any; };
    recursion yes;
    forward first;
    forwarders {
      192.168.10.2;
    };
    dnssec-enable yes;
    dnssec-validation yes;
    dnssec-lookaside auto;
    /* Path to ISC DLV key */
    bindkeys-file "/etc/named.iscdlv.key";
    managed-keys-directory "/var/named/dynamic";
  };
  zone "corp.contoso.io" IN {
      type master;
      file "corp.contoso.io.zone";
      allow-update { none; };
  };
  EOF
  cat <<EOF > /var/named/corp.contoso.io.zone
  \$TTL 86400
  @   IN  SOA     ns1.mydomain.com. root.mydomain.com. (
          2013042201  ;Serial
          3600        ;Refresh
          1800        ;Retry
          604800      ;Expire
          86400       ;Minimum TTL
  )
  ; Specify our two nameservers
      IN	NS		dnsA.corp.contoso.io.
      IN	NS		dnsB.corp.contoso.io.
  ; Resolve nameserver hostnames to IP, replace with your two droplet IP addresses.
  dnsA		IN	A		1.1.1.1
  dnsB	  IN	A		8.8.8.8
  
  ; Define hostname -> IP pairs which you wish to resolve
  @		  IN	A		${aws_instance.onpremapp.private_ip}
  app		IN	A	  ${aws_instance.onpremapp.private_ip}
  EOF
  service named restart
  chkconfig named on
  cd /tmp 
  sudo yum install -y https://s3.${var.region_secondary}.amazonaws.com/amazon-ssm-${var.region_secondary}/latest/linux_amd64/amazon-ssm-agent.rpm 
  sudo systemctl enable amazon-ssm-agent 
  sudo systemctl start amazon-ssm-agent    

EOT
}

resource "aws_instance" "onpremapp" {
  provider = aws.secondary
  depends_on = [
    aws_vpc_endpoint.onpremssminterfaceendpoint,
    aws_vpc_endpoint.onpremssmec2messagesinterfaceendpoint,
    aws_vpc_endpoint.onpremssmmessagesinterfaceendpoint
  ]
  ami                    = data.aws_ami.amazon-linux-2_secondary.id
  instance_type          = "t2.micro"
  iam_instance_profile   = data.aws_iam_instance_profile.EC2profile_secondary.name
  subnet_id              = aws_subnet.onprem-private-b.id
  vpc_security_group_ids = [aws_security_group.OnPremSecurityGroup.id]
  tags = {
    Name = "micros4l-onpremapp-${random_id.rando_secondary.hex}"
  }
  user_data = <<EOF
  #!/bin/bash -xe
  cd /tmp 
  sudo yum install -y https://s3.${var.region_secondary}.amazonaws.com/amazon-ssm-${var.region_secondary}/latest/linux_amd64/amazon-ssm-agent.rpm 
  sudo systemctl enable amazon-ssm-agent 
  sudo systemctl start amazon-ssm-agent

EOF  
}
