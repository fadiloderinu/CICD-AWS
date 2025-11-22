# Quick Start Guide

## 🚀 Deploy Everything in 3 Commands

```powershell
cd "c:\Users\fadil\Terraform AWS\CICD-AWS"

# 1. Edit your GitHub credentials
notepad terraform.tfvars

# 2. Run deployment
.\deploy.ps1

# 3. Get your app URL
terraform output alb_dns_name
```

## 📝 What You Need Before Running

1. **AWS Account** - With console access
2. **AWS CLI** - Installed and configured (`aws configure`)
3. **Terraform** - Installed (v1.0+)
4. **Docker** - Installed and running
5. **GitHub Account** - With a repository
6. **GitHub Personal Access Token** - From https://github.com/settings/tokens/new

## 🔑 Creating GitHub Token

1. Go to https://github.com/settings/tokens/new
2. Name it: `AWS-CodePipeline`
3. Select scopes:
   - ✓ `repo` (Full control of private repositories)
   - ✓ `admin:repo_hook` (Write access to hooks and events)
4. Click "Generate token"
5. **Copy immediately** (you won't see it again!)
6. Paste into `terraform.tfvars` as `github_token`

## 📋 terraform.tfvars Template

```hcl
aws_region          = "us-east-1"
app_name            = "assignment3"
ecr_repository_uri  = "505285757529.dkr.ecr.us-east-1.amazonaws.com/assignment3"
use_existing_ecr    = true

github_owner  = "your-github-username"
github_repo   = "your-repo-name"
github_branch = "main"
github_token  = "ghp_paste_your_token_here"
```

## ⏱️ Deployment Timeline

- **Terraform init**: ~30 seconds
- **Terraform plan**: ~30 seconds  
- **Terraform apply**: 5-10 minutes (creates VPC, subnets, ECS, ALB, etc.)
- **ECS tasks startup**: 1-2 minutes
- **ALB health checks**: 1-2 minutes
- **Total**: ~10-15 minutes

## ✅ Verify Deployment

```powershell
# Test the app
$ALB_DNS = terraform output -raw alb_dns_name
curl http://$ALB_DNS

# Check ECS status
aws ecs describe-services --cluster assignment3-cluster --services assignment3-service --region us-east-1

# View logs
aws logs tail /ecs/assignment3 --follow

# Check pipeline
aws codepipeline get-pipeline-state --name assignment3-pipeline --region us-east-1
```

## 🔄 Trigger CI/CD Pipeline

Push code to GitHub:

```powershell
# Make a change
echo "# Updated" >> README.md

# Commit and push
git add .
git commit -m "Trigger pipeline"
git push origin main
```

The pipeline will automatically:
1. Pull code from GitHub
2. Build Docker image with CodeBuild
3. Push to ECR
4. Update ECS service
5. Deploy new container

## 🗑️ Cleanup (Remove Everything)

```powershell
# Destroy all AWS resources
terraform destroy

# Confirm with 'yes' when prompted
# This will delete VPC, ECS, ALB, ECR, CodePipeline, etc.
```

## 🆘 Troubleshooting

### App not accessible
```powershell
# Check ALB
aws elbv2 describe-load-balancers --region us-east-1

# Check target group health
aws elbv2 describe-target-groups --region us-east-1
aws elbv2 describe-target-health --target-group-arn <arn> --region us-east-1
```

### ECS tasks not running
```powershell
# List tasks
aws ecs list-tasks --cluster assignment3-cluster --region us-east-1

# Describe task
aws ecs describe-tasks --cluster assignment3-cluster --tasks <task-arn> --region us-east-1

# View logs
aws logs tail /ecs/assignment3 --follow
```

### CodePipeline failed
```powershell
# Check pipeline status
aws codepipeline get-pipeline-state --name assignment3-pipeline --region us-east-1

# View CodeBuild logs
aws logs tail /aws/codebuild/assignment3 --follow
```

### GitHub webhook not working
```powershell
# Check CodePipeline configuration
aws codepipeline get-pipeline --name assignment3-pipeline --region us-east-1

# Verify GitHub credentials
aws codepipeline put-webhook --cli-input-json file://webhook.json --region us-east-1
```

## 📊 Monitor Everything

```powershell
# Real-time ECS logs
aws logs tail /ecs/assignment3 --follow

# Real-time CodeBuild logs
aws logs tail /aws/codebuild/assignment3 --follow

# ECS service health
aws ecs describe-services --cluster assignment3-cluster --services assignment3-service --region us-east-1 --output table

# ALB status
aws elbv2 describe-load-balancers --region us-east-1 --output table
```

## 📁 File Structure

```
c:\Users\fadil\Terraform AWS\CICD-AWS\
├── app.py                        # Your Flask app
├── Dockerfile                    # Container configuration
├── requirements.txt              # Python dependencies
├── buildspec.yml                 # CodeBuild build steps
├── main.tf                       # VPC, ECS, ALB
├── cicd.tf                       # CodePipeline, CodeBuild
├── variables.tf                  # Common variables
├── github-variables.tf           # GitHub variables
├── outputs.tf                    # Output values
├── terraform.tfvars              # Your configuration (CREATE THIS)
├── terraform.tfvars.example      # Template
├── deploy.ps1                    # Deployment script
└── README.md                     # Full documentation
```
