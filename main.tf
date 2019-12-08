provider "aws" {
  region = var.region
}

data "aws_availability_zones" "avzones" {}

data "aws_ami" "latest_ami" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

#-----------------------Resource----------------------

# resource "tls_private_key" "alg" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }
#
# resource "aws_key_pair" "generated_key" {
#   key_name   = var.key_name
#   public_key = tls_private_key.alg.public_key_openssh
# }

resource "aws_iam_role" "bhrole" {
  name = "BastionHostRole"

  assume_role_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    }
EOF
}

resource "aws_iam_policy" "bhpolicy" {
  name        = "BastionHostPolicy"
  description = "Policy for BastionHost"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": ["ec2:AssociateAddress","ec2:DisassociateAddress"],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "bhpolicy-attach" {
  role       = aws_iam_role.bhrole.name
  policy_arn = aws_iam_policy.bhpolicy.arn
}

resource "aws_iam_instance_profile" "bh_profile" {
  name = "BastionHostprofile"
  role = aws_iam_role.bhrole.name
}

resource "aws_eip" "ec2eip" {
  #  name = "BastionHost-EIP"
  vpc = true
  tags = {
    Name   = "BastionHost-EIP"
    Region = var.region
  }
}

resource "aws_security_group" "webSG" {
  name        = "Security group for Bastion Host"
  description = "Allow inbound traffic from 22 ports"

  dynamic "ingress" {
    for_each = var.allow_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "bhlaunch" {
  name                 = "BastionHost-LaunchCF"
  image_id             = data.aws_ami.latest_ami.id
  instance_type        = var.instance_type
  security_groups      = [aws_security_group.webSG.id]
  iam_instance_profile = aws_iam_instance_profile.bh_profile.id
  user_data            = file("user_data.sh")
  key_name             = var.key_pair

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bhasg" {
  name                 = "Bastion-Host"
  launch_configuration = aws_launch_configuration.bhlaunch.name
  min_size             = 1
  max_size             = 1
  desired_capacity     = 1
  health_check_type    = "EC2"
  vpc_zone_identifier  = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]

  tags = [
    {
      key                 = "Name"
      value               = "BastionHost-ASG"
      propagate_at_launch = true
    }
  ]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.avzones.names[0]
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = data.aws_availability_zones.avzones.names[1]
}
