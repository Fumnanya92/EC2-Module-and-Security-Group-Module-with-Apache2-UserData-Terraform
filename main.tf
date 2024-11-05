# Security Group Module
module "security_group" {
  source = "./modules/security_group"
}

# EC2 Instance Module
module "ec2_instance" {
  source            = "./modules/ec2"
  security_group_id = module.security_group.security_group_id # Passes the Security Group ID output from the security_group module
  user_data         = file("apache_userdata.sh")              # References the external user data script
}