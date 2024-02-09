resource "aws_security_group" "prometheus" {
  name        = "prometheus"
  description = "Allow SSH, HTTP(S), Prometheus"
  vpc_id      = aws_vpc.firefly.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Prometheus"
    from_port        = 2112 
    to_port          = 2112
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "prometheus"
  }
}

data "aws_ami" "base_ami" {
  most_recent      = true
  owners           = ["amazon"]
 
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
 
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
 
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
 
}

resource "aws_iam_instance_profile" "eks-cluster-demo" {
  name = "eks-cluster-demo"
  role = aws_iam_role.demo.name
}

locals {
  aws_credentials_filename = fileexists("/home/ec2-user/.aws/credentials") ? "/home/ec2-user/.aws/credentials" : "/home/scott/.aws/credentials"
  ssh_private_key_filename = fileexists("/home/ec2-user/.ssh/IK.pem") ? "/home/ec2-user/.ssh/IK.pem" : "/home/scott/.ssh/IK.pem"
}

resource "aws_instance" "firefly-prometheus" {
  ami           = data.aws_ami.base_ami.id
  instance_type = "t3.medium"
  key_name = "IK"
  iam_instance_profile = aws_iam_instance_profile.eks-cluster-demo.name
  subnet_id = aws_subnet.public-us-west-1a.id
  vpc_security_group_ids = [aws_security_group.prometheus.id]

  tags = {
    Name = "firefly-prometheus"
  }

  connection {
    type = "ssh"
    host = aws_instance.firefly-prometheus.public_ip
    user = "ec2-user"
    private_key = "${file(local.ssh_private_key_filename)}"
    agent = true
  }

  provisioner "file" {
    source = local.aws_credentials_filename
    destination = "/tmp/credentials"
  }

  provisioner "remote-exec" {
    inline = [
      "/usr/bin/wget -O /tmp/config_prometheus.sh https://raw.githubusercontent.com/scottkaplan/k8s_monitoring/main/ansible/config_prometheus.sh",
      "/bin/bash /tmp/config_prometheus.sh",
    ]
  }
}

resource "aws_eip" "firefly-prometheus" {
  instance = aws_instance.firefly-prometheus.id
}

data "aws_route53_zone" "kaplans" {
  name = "kaplans.com"
}

resource "aws_route53_record" "firefly-prometheus" {
  zone_id = data.aws_route53_zone.kaplans.zone_id
  name    = "firefly-prometheus.kaplans.com"
  type    = "A"
  ttl     = 300
  records = [aws_eip.firefly-prometheus.public_ip]
}

