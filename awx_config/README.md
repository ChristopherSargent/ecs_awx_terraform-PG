![alt text](ecs.logo.JPG)
* This repository contains detailed instructions for configuring AWX for use. For any additional details or inquiries, please contact us at c.sargent-ctr@ecstech.com.

# [AWX Project Page](https://github.com/ansible/awx)
* Note AWX is the opensourced Ansible Automation Platform
# [Ansible Automation Plaform](https://www.redhat.com/en/technologies/management/ansible)

# Configure Organization
1. https://awx-pg-terraform-alb-1606754339.us-gov-west-1.elb.amazonaws.com > Login to AWX

![Screenshot](resources/awxlogin.JPG)

2. Access > Organizations > Add

![Screenshot](resources/org1.JPG)

3. Name = ECS > Save

![Screenshot](resources/org2.JPG)

# Configure Credentials
1. https://awx-pg-terraform-alb-1606754339.us-gov-west-1.elb.amazonaws.com > Login to AWX

![Screenshot](resources/awxlogin.JPG)

2. Resources > Credentials > Add

![Screenshot](resources/creds1.JPG)

3. Name = terraform_service_user > Credential Type = Amazon Wed Services > Organization = ECS > Add Access Key and Secret Key > Save

![Screenshot](resources/creds2.JPG)

# Configure Inventory Sync
1. https://awx-pg-terraform-alb-1606754339.us-gov-west-1.elb.amazonaws.com > Login to AWX

![Screenshot](resources/awxlogin.JPG)

2. Resources > Inventories > Add > Add inventory

![Screenshot](resources/inv1.JPG)

3. Name = playground_inventory > Organization = ECS > Save

![Screenshot](resources/inv2.JPG)

4. Resources > Inventories > playground_inventory > Sources > Add

![Screenshot](resources/inv3.JPG)

5. Name = playground_inventory_source > Credential = terraform_service_user > Select Overwrite > Select Update on launch > Add regions: us-gov-west-1 to source variables

![Screenshot](resources/inv4.JPG)

6. Resources > Inventories > playground_inventory > Sources > Sync

![Screenshot](resources/inv5.JPG)

7. Resources > Inventories > playground_inventory > Hosts > Verify hosts are populated

![Screenshot](resources/inv6.JPG)

# Configure Localhost Inventory
1. https://awx-pg-terraform-alb-1606754339.us-gov-west-1.elb.amazonaws.com > Login to AWX

![Screenshot](resources/awxlogin.JPG)

2. Resources > Inventories > Add > Add inventory

![Screenshot](resources/inv1.JPG)

3. Name = localhost_inventory > Organization = ECS > Save

![Screenshot](resources/inv7.JPG)

# Configure Project
1. https://awx-pg-terraform-alb-1606754339.us-gov-west-1.elb.amazonaws.com > Login to AWX

![Screenshot](resources/awxlogin.JPG)

2. Resources > Projects > Add > Name = deploy_ec2 > Description = Deploy ec2 instance and security group with allow rules for ssh/https. > Organization = ECS > Source Control Type = Manual > Playbook Directory = deploy_ec2 > Save

![Screenshot](resources/projects1.JPG)

![Screenshot](resources/projects2.JPG)

# Configure Template
1. https://awx-pg-terraform-alb-1606754339.us-gov-west-1.elb.amazonaws.com > Login to AWX

![Screenshot](resources/awxlogin.JPG)

2. Resources > Templates > Add > Add job template > Name = deploy_ec2 > Description = Deploy ec2 instance and security group with allow rules for ssh/https. > Job Type = Run > Inventory = localhost_inventory > Project = deploy_ec2 > Playbook = create_ec2instance.yml > Credentials = Cloud:terraform_service_user > Save

![Screenshot](resources/templates1.JPG)

![Screenshot](resources/templates2.JPG)


# Configure Survey
1. https://awx-pg-terraform-alb-1606754339.us-gov-west-1.elb.amazonaws.com > Login to AWX

![Screenshot](resources/awxlogin.JPG)

2. Resources > Templates > deploy_ec2

![Screenshot](resources/templates1.JPG)

3. Survey > Add > Question = security_group_name > Description = Security_Group_Name > Answer variable name = security_group_name > Answer type = Text > Save 
* Note to repeat for any variables needed. Note also that for public_ip the answer type is boolean not text.

![Screenshot](resources/survey1.JPG)

![Screenshot](resources/survey2.JPG)




