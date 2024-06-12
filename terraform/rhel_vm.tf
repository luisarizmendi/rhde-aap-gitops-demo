variable "aws_region" {
  description = "AWS region where the instance will be launched"
  default     = "eu-west-1"
}

variable "ami_id" {
  description = "AMI ID for RHEL 9"
  default     = "ami-028f9616b17ba1d53"
}

variable "instance_type" {
  description = "Instance type for the RHEL VM"
  default     = "m4.xlarge"
}

variable "key_pair_name" {
  description = "Name of your AWS key pair"
  default     = "myrhelkey"
}

variable "admin_user" {
  description = "Name of admin user"
  default     = "admin"
}

variable "admin_pass" {
  description = "Password of admin user"
  default     = "R3dh4t1!"
}

variable "ssh_key_file" {
  description = "Location of the Public SSH key"
  default     = "~/.ssh/id_rsa.pub"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "edge_mgmt_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "edge_mgmt_vpc"
  }
}

resource "aws_subnet" "edge_mgmt_subnet" {
  vpc_id            = aws_vpc.edge_mgmt_vpc.id
  cidr_block        = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "edge_mgmt_subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.edge_mgmt_vpc.id

  tags = {
    Name = "InternetGateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.edge_mgmt_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.edge_mgmt_subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_key_pair" "keypair" {
  key_name   = var.key_pair_name
  public_key = file(var.ssh_key_file)
}

resource "aws_instance" "edge_mgmt_vm" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.keypair.key_name
  subnet_id     = aws_subnet.edge_mgmt_subnet.id
  associate_public_ip_address = true

  root_block_device {
    volume_size = 250
  }

  tags = {
    Name = "Edge_MGMT_VM"
  }

  depends_on = [aws_vpc.edge_mgmt_vpc]

  vpc_security_group_ids = [aws_security_group.edge_mgmt_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum -y update
              sudo useradd -m ${var.admin_user}
              sudo usermod -aG wheel ${var.admin_user}
              sudo sed -i -e 's/^# %wheel/%wheel/' -e 's/^%wheel/# %wheel/' /etc/sudoers
              sudo sed -i -e 's/^%wheel/# %wheel/' -e 's/^# %wheel/%wheel/' /etc/sudoers
              sudo -u ${var.admin_user} mkdir -p /home/${var.admin_user}/.ssh
              sudo -u ${var.admin_user} bash -c "echo '${aws_key_pair.keypair.public_key}' > /home/${var.admin_user}/.ssh/authorized_keys"
              sudo -u ${var.admin_user} ssh-keygen -t rsa -f /home/admin/.ssh/id_rsa -N ""
              sudo -u ${var.admin_user} cat .ssh/id_rsa.pub >> .ssh/authorized_keys
              sudo -u ${var.admin_user} chmod 700 /home/${var.admin_user}/.ssh
              sudo -u ${var.admin_user} chmod 600 /home/${var.admin_user}/.ssh/authorized_keys
              sudo usermod --password $(echo ${var.admin_pass} | openssl passwd -1 -stdin) ${var.admin_user}
              sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
              sudo systemctl restart sshd
              EOF
}

resource "aws_eip" "edge_mgmt_eip" {
  instance = aws_instance.edge_mgmt_vm.id
  vpc      = true

  tags = {
    Name = "Edge_MGMT_EIP"
  }
}

resource "aws_security_group" "edge_mgmt_sg" {
  vpc_id      = aws_vpc.edge_mgmt_vpc.id
  name        = "RHEL_Security_Group"
  description = "Security group for Edge_MGMT_VM"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 18080
    to_port     = 18080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 18081
    to_port     = 18081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 18082
    to_port     = 18082
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 18083
    to_port     = 18083
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8444
    to_port     = 8444
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8445
    to_port     = 8445
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Use -1 to specify all protocols
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow ESP protocol"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "ipsec_ports" {
  type              = "ingress"
  from_port         = 500
  to_port           = 500
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.edge_mgmt_sg.id
}

resource "aws_security_group_rule" "ipsec_protocol" {
  type              = "ingress"
  from_port         = 4500
  to_port           = 4500
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.edge_mgmt_sg.id
}

output "public_ip" {
  value = aws_eip.edge_mgmt_eip.public_ip
}
