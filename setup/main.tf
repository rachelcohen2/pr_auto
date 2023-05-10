provider "aws" {
  region = "eu-west-2"
}

##########################################################
# # Networking Module
#########################################################

module "networking" {
  source = "../modules/Networking"
}

# module "imagepipeline" {
#   source = "../modules/imagepipeline"
#   project-name = "s3_for_code_pipeline"
#   bucket-of-objects = "bucket-for-code-pipeline-${random_integer.this.result}"
#   key_alias = "alias/${random_integer.this.result}"
#   logging_bucket_name = "logging-bucket-${random_integer.this.result}"
#   team_name = "team_name"
# }
##########################################################
# # Creating the latest aws linux ami version
#########################################################


data "aws_ami" "latest_ecs" {
  most_recent = true 

  filter {
    name = "name"
    values = ["amzn-ami*amazon-ecs-optimized"] 
  }

  owners = [
    "amazon" 
  ]
}


##########################################################
# Esc Module
#########################################################

# module "ecs" {
#     source = "../modules/Ecs"
#     ecr = "ecr-repo-name"
#     ecr-img = "ecr-image"
#     ecs-role = aws_iam_role.ecs-instance-role.name
#     ecs-service-role-id = aws_iam_role.ecs-service-role.id
#     ecs_cluster_name = "ecsdevlcluster"
#     ami = data.aws_ami.latest_ecs.image_id
#     instance_type = "t2.small"
#     main_key = "m_key"
#     lb_target_group_name = "openapi-target-alb-name"
#     launch_type = "EC2"
#     service_name = "openapiservice-jk"
#     container_name = "openapi-ecs-container"
#     container_port = "8080"
#     cloudwatch_log_group_name = "openapi-devl-cw"
#     r53 = "vpn-devl.us.e10.c01.example.com."
#     dns = "openapi-editor-devl"
#     vpc_id = module.networking.vpc_id
#     sg_id = module.networking.security_group_id
#     private_subnet_b_ip = module.networking.private_sub_b
#     private_subnet_a_ip = module.networking.private_sub_a
#     public_sub_a = module.networking.public_sub_a
#     public_sub_b = module.networking.public_sub_b
#     nat_private_sub = module.networking.nat_private_sub
# } 

module "Ecs_wtd" {
  source = "../modules/Ecsa"
  ami = data.aws_ami.latest_ecs.id
  subnet-zone = module.networking.private_sub_a
  sg = module.networking.security_group_id
  vpc = module.networking.vpc_ip
}
##########################################################
# Creating a random number for the buckets name
#########################################################

resource "random_integer" "this" {
  min = 1
  max = 50000
}

##########################################################
# Code Pipeline Module
#########################################################

# module "code_pipeline" {
#   source = "../modules/Codepipeline"
#   iam_role_policy_codepipeline = "iam_role_pipeline_for_jenkins"
#   name = "pipeline_for_jenkins"
#   artifact_store_type  = "S3"
#   encryption_key_type = "KMS"
#   aws_codestarconnections_name = "jk_codestarconnections"
#   codestarconnections_provider_type  =  "GitHub"
#   codepipeline_acl = "private"
#   iam_role_codepipeline_name  = "codepipeline_role_name"
#   logging_bucket_name = "logging-bucket-${random_integer.this.result}"
#   team_name = "team_name"
#   project-name = "s3_for_code_pipeline"
#   bucket-of-objects = "bucket-for-code-pipeline-${random_integer.this.result}"
#   key_alias = "alias/${random_integer.this.result}"
# }

##########################################################
# Attaching an ecs policy to the ecs role
#########################################################

resource "aws_iam_role_policy_attachment" "ecs-instance-role-attachment" {
   role = "${aws_iam_role.ecs-instance-role.name}"
   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

##########################################################
# Creating the ecs role
#########################################################

resource "aws_iam_role" "ecs-instance-role" {
  name = "ecs-instance-role"
  path = "/"
  permissions_boundary = "arn:aws:iam::629343647160:policy/PCSKPermissionsBoundary"
  assume_role_policy = "${data.aws_iam_policy_document.ecs-instance-policy.json}"
}

##########################################################
# Creating an iam instance profile
#########################################################

resource "aws_iam_instance_profile" "ecs-instance-pro" {
  name = "ecs-instance-profile-10"
  path = "/"
  role = "${aws_iam_role.ecs-instance-role.id}"
  provisioner "local-exec" {
  command = "sleep 60"
 }
}

##########################################################
# Create a policy for ecs instance access
#########################################################

data "aws_iam_policy_document" "ecs-instance-policy" {
  statement {
  actions = ["sts:AssumeRole"]
  principals {
  type = "Service"
  identifiers = ["ec2.amazonaws.com"]
  }
 }
}

##########################################################
# Create a policy for creating an ecs service
#########################################################

data "aws_iam_policy_document" "ecs-service-policy" {
  statement {
  actions = ["sts:AssumeRole"]
  principals {
  type = "Service"
  identifiers = ["ecs.amazonaws.com"]
  }
 }
}

##########################################################
# Create a role for ecs instance access
#########################################################

resource "aws_iam_role" "ecs-service-role" {
  name = "ecs-service-role"
  path = "/"
  permissions_boundary = "arn:aws:iam::629343647160:policy/PCSKPermissionsBoundary"
  assume_role_policy = "${data.aws_iam_policy_document.ecs-service-policy.json}"
}


##########################################################
# Attaching the service policy to the service role
#########################################################
resource "aws_iam_role_policy_attachment" "ecs-service-role-attachment" {
  role = "${aws_iam_role.ecs-service-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

# module "s3" {
#   source = "https://git.soma.salesforce.com/terraform-modules/terraform-aws-s3_bucket2/tree/3.1.1"
# }

# module "logging_bucket" {
#   source = "../submodules/s3_bucket/logging"
#   name         = var.logging_bucket_name
# }

# module "s3" {
#   source = "../submodules/s3_bucket/bucket"
#   name           = "${local.bucket_name}"
#   key_alias      = var.key_alias
#   project_name   = "${local.project_name}"
#   team_name      = "${local.team_name}"
#   logging_bucket = "${module.logging_bucket.id}"
# }