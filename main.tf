terraform {
  cloud {
    organization = "AWS-np"

    workspaces {
      name = "provisioners"
    }
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.6.0"
    }
  }
}
 
provider "aws" {
  region = "us-east-1"
}

/* Reference a default vpc id as datasource - vpc-056c23ac9f93f0f14*/
data "aws_vpc" "GCBVPC" {
  /*id = "vpc-056c23ac9f93f0f14"*/
  id = "	vpc-d579ebaf"
}
/* Creates an AWS Security Group - def new */
resource "aws_security_group" "sg_cert_server" {
  name        = "sg_cert_server"
  description = "sg_cert_server Allow TLS inbound traffic"
  vpc_id      = data.aws_vpc.GCBVPC.id

  ingress {
    description = "HTTP"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["98.109.133.173/32"]
    ipv6_cidr_blocks = []
    security_groups = []
      self = false
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

/* Creates provisioner of yaml file type */
data "template_file" "user_data" {
    template = "${file("${path.module}/userdata.yaml")}"
}

/* Key Pair Definition */
resource "aws_key_pair" "terraform" {
  key_name   = "terraform"
  public_key = <<EOT
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0NAecRoyVcPuOzj1VEV+
NbVaHk2tD6eKr6FdGOErxUgSIRDlX1QeM9hLZgqDYr9ZLB0gvxckVHf5SkEborAe
QAi2c9bgu1HHZubTvVzatuHtxCRyR0hIeaeO83WqB9C8T0+AXLMd6kXIOBvjg6qR
Aw3lckhrh+fENyPvJeOSf/qjudlHzDUm/MuyS1Qd3OUXtFFH3rlSgG7aq+Id5T3G
quqwBABPvE3wPOOSmnXYQQZYMAfxUXXrQMElpzSsIQgPStBxVMuUz7ZmBF609ar6
BGYeNoOKGQ1j5ezPfS9LftuGmcVCxPh5SrubDcIjnmaQfHwIkjyh+BIk+D0AUcY5
lQIDAQAB
EOT
}

/* Creates an AWS Instance */
resource "aws_instance" "cert_server" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.terraform.key_name}"
  vpc_security_group_ids = [aws_security_group.sg_cert_server.id]
  user_data = "$data.template_file.user_data.rendered}"
  tags = {
    Name = "cert-server"
  }
}

output "public_ip"{
    value = aws_instance.cert_server
}
