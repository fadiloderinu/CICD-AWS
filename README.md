# AWS ECS CI/CD Infrastructure with Terraform

This Terraform configuration creates a complete AWS CI/CD pipeline for deploying a containerized application to ECS with advanced security and auto-scaling features.

## Architecture Overview

```
GitHub Repository
       ↓
   CodePipeline
       ↓
   CodeBuild (Build & Scan)
       ↓
   ECR (with image scanning)
       ↓
   ECS Cluster (in private subnets)
       ↓
   Load Balancer
       ↓
   Internet Users
```

## Features Implemented

✅ **GitHub Integration** - Source code stored in GitHub  
✅ **CI/CD Pipeline** - CodePipeline with automated build and deployment  
✅ **Container Build** - CodeBuild builds Docker images  
✅ **Image Registry** - ECR with container security scanning  
✅ **VPC & Networking** - Custom VPC with public and private subnets  
✅ **NAT Gateways** - Private subnet internet access via NAT  
✅ **Load Balancing** - Application Load Balancer distributing traffic  
✅ **Security Groups** - Segmented security at ALB and ECS levels  
✅ **ECS Cluster** - Fargate launch type with capacity providers  
✅ **Auto-scaling** - CPU and memory-based auto-scaling  
✅ **Task Definition** - CloudWatch logging integrated  
✅ **Private Deployment** - ECS tasks run in private subnets only  

## Prerequisites

1. **AWS Account** - Active AWS account with appropriate permissions
2. **Terraform** - v1.0+ installed
3. **AWS CLI** - Configured with credentials
4. **GitHub Token** - Personal access token with repo scope
5. **Git** - For version control

## Setup Instructions

### 1. Clone or Initialize the Repository

```bash
cd "c:\Users\fadil\Terraform AWS\CICD-AWS"
```

### 2. Create terraform.tfvars

Copy the example file and update with your values:

```bash
Copy-Item terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and add:

```hcl
aws_region          = "us-east-1"
app_name            = "hello-ecs-app"
github_owner        = "your-github-username"
github_repo         = "your-repo-name"
github_branch       = "main"
github_token        = "ghp_xxxxxxxxxxxxxxxxxxxx"  # Get from https://github.com/settings/tokens
```

### 3. Generate GitHub Personal Access Token

1. Go to https://github.com/settings/tokens
2. Click "Generate new token" → "Generate new token (classic)"
3. Select scopes: `repo`, `admin:repo_hook`
4. Copy the token and add to `terraform.tfvars`

### 4. Push Your Code to GitHub

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/your-username/your-repo.git
git push -u origin main
```

### 5. Initialize Terraform

```bash
terraform init
```

### 6. Plan the Infrastructure

```bash
terraform plan -out=tfplan
```

### 7. Apply the Configuration

```bash
terraform apply tfplan
```

This will create:
- VPC with 2 public and 2 private subnets
- Internet Gateway and NAT Gateways
- Application Load Balancer
- ECS Cluster with Fargate
- ECR Repository with image scanning
- CodePipeline with CodeBuild
- Auto-scaling policies
- CloudWatch logging

## File Structure

```
.
├── main.tf                    # VPC, Subnets, Security Groups, ECS Cluster
├── cicd.tf                    # CodePipeline, CodeBuild, IAM roles
├── variables.tf               # Common variables
├── github-variables.tf        # GitHub-specific variables
├── outputs.tf                 # Output values
├── Dockerfile                 # Container configuration
├── app.py                     # Python Flask application
├── requirements.txt           # Python dependencies
└── terraform.tfvars.example   # Example variable values
```

## Configuration Details

### VPC Architecture
- **CIDR**: 10.0.0.0/16
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24 (with Internet Gateway)
- **Private Subnets**: 10.0.11.0/24, 10.0.12.0/24 (with NAT Gateway)

### ECS Configuration
- **Launch Type**: Fargate
- **Task CPU**: 256 (adjustable)
- **Task Memory**: 512 MB (adjustable)
- **Desired Count**: 2 (auto-scales 2-4)
- **Container Port**: 5000

### Auto-scaling Policies
- **CPU**: Scale up at 70% utilization
- **Memory**: Scale up at 80% utilization
- **Min Capacity**: 2 tasks
- **Max Capacity**: 4 tasks

## Accessing Your Application

After deployment, get the ALB endpoint:

```bash
terraform output alb_dns_name
```

Open in browser: `http://<alb-dns-name>`

You should see: **"Hello from lastname ECS Container."**

## CI/CD Pipeline Workflow

1. **Push Code to GitHub** - Triggers CodePipeline
2. **CodePipeline Source Stage** - Pulls code from GitHub
3. **CodeBuild Build Stage** - Builds Docker image and scans for vulnerabilities
4. **ECR Push** - Pushes image to ECR repository
5. **CodePipeline Deploy Stage** - Updates ECS service with new image
6. **ECS Update** - New tasks launch with updated image

## Security Features

- **Container Security Scanning**: Enabled on all ECR images (scan on push)
- **Private Deployment**: ECS tasks only run in private subnets
- **NAT Gateway**: Private subnets access internet through NAT
- **Security Groups**: Restricted ingress/egress rules
- **IAM Roles**: Least privilege IAM policies
- **Secrets**: GitHub token stored as sensitive in Terraform

## Monitoring & Logging

- **CloudWatch Log Group**: `/ecs/hello-ecs-app`
- **Container Insights**: Enabled on ECS cluster
- **CodeBuild Logs**: `/aws/codebuild/hello-ecs-app`
- **ALB Logs**: (Optional - not configured by default)

## Updating Configuration

To modify resources:

1. Edit the appropriate `.tf` file
2. Run `terraform plan` to review changes
3. Run `terraform apply` to update

### Scaling Tasks

Update in `terraform.tfvars`:
```hcl
ecs_min_capacity = 2
ecs_max_capacity = 8
```

### Changing Image

Push new code to GitHub - pipeline automatically builds and deploys!

## Cost Estimation

Typical monthly costs (rough estimate):
- NAT Gateway: ~$32
- ALB: ~$16
- ECS Fargate: ~$15-40 (depends on utilization)
- ECR: ~$0.10
- Data Transfer: varies

## Troubleshooting

### Pipeline Failed
Check CodeBuild logs:
```bash
aws logs tail /aws/codebuild/hello-ecs-app --follow
```

### Image Not Updating
1. Verify image pushed to ECR: `terraform output ecr_repository_url`
2. Check ECS task logs: `aws logs tail /ecs/hello-ecs-app --follow`
3. Manually force ECS update:
```bash
aws ecs update-service --cluster hello-ecs-app-cluster --service hello-ecs-app-service --force-new-deployment
```

### ALB Health Checks Failing
- Verify app is listening on port 5000
- Check security group rules
- Review ECS task logs

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

Confirm with `yes` when prompted.

## Next Steps

1. **Custom Domain**: Add Route 53 DNS record pointing to ALB
2. **HTTPS/SSL**: Add ACM certificate to ALB listener
3. **Alerting**: Add SNS notifications for CodePipeline failures
4. **Monitoring**: Configure CloudWatch alarms for CPU/memory
5. **Database**: Add RDS for persistent data storage
6. **Backup**: Configure ECR lifecycle policies and backup

## Support

For Terraform issues: https://discuss.hashicorp.com/c/terraform/15  
For AWS documentation: https://docs.aws.amazon.com/  
For this setup: Check the resource tags and CloudWatch logs
