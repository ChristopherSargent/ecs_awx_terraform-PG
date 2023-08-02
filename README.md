![alt text](ecs.logo.JPG)

# [awx_terraform_pg](https://bitbucket.cdmdashboard.com/projects/DBOPS/repos/awx_terraform_pg/browse)

This repository contains the necessary source code files to deploy a rhel8 AWX ec2 instance from ami and includes ec2, alb, alb-sg, ec2-sg, certificate and target group. For additional details, please email at [c.sargent-ctr@ecstech.com](mailto:c.sargent-ctr@ecstech.com). 

# Deploy This Project from Git
1. ssh -i alpha_key_pair.pem ec2-user@PG-TerraformPublicIP
2. cd /home/christopher.sargent/ && git clone https://bitbucket.cdmdashboard.com/projects/DBOPS/repos/awx_terraform_pg.git
3. cd awx_terraform_pg/ && vim providers.tf
```
# Playground 
provider "aws" {
  region = var.selected_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
```
4. vim alpha_key_pair.pem
```
# alpha_key_pair.pem.pem key is in AWS secrets manager in playground. Cut and paste key into this file and save
```
5. chmod 400 alpha_key_pair.pem
6. vim variables.tf
```
Playground terraform_service_user aws_access_key and aws_secret_key is in AWS secrets manager
variable "aws_access_key" {
  type    = string
  default = "" # specify the access key
}
variable "aws_secret_key" {
  type    = string
  default = "" # specify the secret key
}
variable "selected_region" {
  type    = string
  default = "us-gov-west-1" # specify the aws region
}
# aws ssh key
variable "ssh_private_key" {
  default         = "alpha_key_pair.pem"
  description     = "alpha_key_pair"
}
```
7. terraform init && terraform plan --out awx.out
8. terraform apply "awx.out"
9. https://console.amazonaws-us-gov.com > EC2 > search for awx-pg-terraform-ec2 and verify instance is up
10. https://console.amazonaws-us-gov.com > Load Balancers > search for awx-pg-terraform-alb and get DNS name
11. https://DNSnamefromstep10 > Login to AWX

# Update Names
1. ssh -i alpha_key_pair.pem ec2-user@PG-TerraformPublicIP
2. sudo -i
3. cd /home/christopher.sargent/ecs_threatq_terraform_ps
4. cp main.tf main.tf.BAK
5. sed -i -e 's|terraform|terraform01|g' main.tf
```
The resources are now named

awx-pg-terraform01-ec2 and awx-pg-terraform01-alb

versus

awx-pg-terraform-ec2 and awx-pg-terraform-alb
```
# Destroy
1. ssh -i alpha_key_pair.pem ec2-user@PG-TerraformPublicIP
2. sudo -i
3. cd /home/christopher.sargent/awx_terraform_pg
4. terraform destroy
