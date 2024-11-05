# EC2 Module and Security Group Module with Apache2 UserData

## Purpose

In this mini project, we will use Terraform to create modular configurations for deploying an EC2 instance with a specified Security Group and Apache2 installed using UserData.

---

## Project Tasks

### Task 1: EC2 Module

1. **Create Project Directory:**
   ```bash
   mkdir terraform-ec2-apache
   cd terraform-ec2-apache
   ```
2. **Set up EC2 Module Directory:**
   ```bash
   mkdir -p modules/ec2
   ```
3. **Write EC2 Module Configuration:**  
   Inside `modules/ec2/main.tf`, configure the EC2 instance.

   ```hcl
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

   ```

### Task 2: Security Group Module

1. **Set up Security Group Module Directory:**
   ```bash
   mkdir -p modules/security_group
   ```
2. **Write Security Group Configuration:**
   In `modules/security_group/main.tf`, create a Security Group allowing HTTP and SSH traffic.

   ```hcl
   # modules/security_group/main.tf
   resource "aws_security_group" "allow_http" {
     name        = "allow_http"
     description = "Allow HTTP and SSH traffic"

     ingress {
       from_port   = 80
       to_port     = 80
       protocol    = "tcp"
       cidr_blocks = ["0.0.0.0/0"]
     }

     ingress {
       from_port   = 22
       to_port     = 22
       protocol    = "tcp"
       cidr_blocks = ["0.0.0.0/0"]
     }

     egress {
       from_port   = 0
       to_port     = 0
       protocol    = "-1"
       cidr_blocks = ["0.0.0.0/0"]
     }
   }

   output "security_group_id" {
     value = aws_security_group.allow_http.id
   }
   ```

### Task 3: UserData Script

1. **Write UserData Script:**
   Create a file `apache_userdata.sh` to install and configure Apache2.

   ```bash
   # apache_userdata.sh
   #!/bin/bash
   sudo yum update -y
   sudo yum install -y httpd
   sudo systemctl start httpd
   sudo systemctl enable httpd
   echo "<h1>Hello World from $(hostname -f)</h1>" | sudo tee /var/www/html/index.html
   ```
2. **Make the UserData Script Executable:**
   ```bash
   chmod +x apache_userdata.sh
   ```

### Task 4: Main Terraform Configuration

1. **Create Main Terraform Configuration:**
   In `main.tf`, set up the main configuration to use the EC2 and Security Group modules.

   ```hcl
   # main.tf
   provider "aws" {
     region = "us-west-2" # Replace with desired region
   }

   module "security_group" {
     source = "./modules/security_group"
   }

   module "ec2_instance" {
     source           = "./modules/ec2"
     security_group_id = module.security_group.security_group_id
     user_data         = file("apache_userdata.sh")
   }
   ```

### Task 5: Deployment

1. **Initialize and Deploy the Configuration:**
   ```bash
   terraform init
   terraform fmt
   terraform validate
   terraform plan
   terraform apply
   ```
   Confirm with `yes` to deploy the EC2 instance and Security Group.

2. **Access the EC2 Instance:**  
   Copy the public IP from the Terraform output or AWS Console, then access it in a browser to verify Apache2 is running. The message `Hello World from <hostname>` should appear.

---

## Observations and Challenges

1. **Module Reusability:**  
   Modularizing configurations made the setup more organized and reusable. Changes in instance details or security settings can now be made in isolation.

2. **AMI Compatibility:**  
   Choosing the right AMI is crucial; an incompatible one could cause failures. Using a region-specific AMI ID or latest AMI helps in deployment without errors.

3. **UserData Debugging:**  
   Ensure the UserData script executes successfully by checking the instance logs (`/var/log/cloud-init.log`). This can be useful if Apache2 does not start as expected.

4. **Network Configuration:**  
   Verifying Security Group rules beforehand is essential. Missing permissions might prevent HTTP or SSH access to the Apache server.

5. **Terraform State Management:**  
   Be cautious with `terraform destroy` and `apply`, as they affect resources directly on AWS. Ensuring the `terraform.tfstate` file is kept safely is critical for tracking resources.

---

This project demonstrates a simple but effective setup for automating an EC2 deployment with Apache2 using Terraform modules, allowing for flexibility and reusability in cloud infrastructure management.
