# modules/ec2/main.tf

variable "security_group_id" {
  description = "The ID of the Security Group to associate with the EC2 instance"
  type        = string
}

variable "user_data" {
  description = "UserData script for the EC2 instance"
  type        = string
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "example_keypair" {
  key_name   = "tfkey"
  public_key = tls_private_key.example.public_key_openssh
}

resource "local_file" "tf_key" {
  content  = tls_private_key.example.private_key_pem
  filename = "tfkey"
}

resource "aws_instance" "example_instance" {
  ami               = "ami-0d081196e3df05f4d"  # Specify the correct AMI ID for your region
  instance_type     = "t2.micro"
  key_name          = aws_key_pair.example_keypair.key_name
  vpc_security_group_ids = [var.security_group_id] # Use the security group ID from the module input
  user_data         = var.user_data                # Use user data from the module input

  tags = {
    Name = "HelloWorld"
  }
}

output "public_ip" {
  value = aws_instance.example_instance.public_ip
}
