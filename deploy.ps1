# Complete deployment script for AWS ECS CI/CD Infrastructure
# Usage: .\deploy.ps1

Write-Host "========================================" -ForegroundColor Green
Write-Host "AWS ECS CI/CD Deployment Script" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Check prerequisites
Write-Host "Step 1: Checking prerequisites..." -ForegroundColor Yellow
$prereqs_ok = $true

if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Host "✗ Terraform not found. Please install Terraform." -ForegroundColor Red
    $prereqs_ok = $false
} else {
    Write-Host "✓ Terraform found" -ForegroundColor Green
}

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Host "✗ AWS CLI not found. Please install AWS CLI." -ForegroundColor Red
    $prereqs_ok = $false
} else {
    Write-Host "✓ AWS CLI found" -ForegroundColor Green
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "✗ Docker not found. Please install Docker." -ForegroundColor Red
    $prereqs_ok = $false
} else {
    Write-Host "✓ Docker found" -ForegroundColor Green
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "✗ Git not found. Please install Git." -ForegroundColor Red
    $prereqs_ok = $false
} else {
    Write-Host "✓ Git found" -ForegroundColor Green
}

if (-not $prereqs_ok) {
    Write-Host ""
    Write-Host "Please install missing prerequisites and try again." -ForegroundColor Red
    exit 1
}

Write-Host ""

# Check AWS credentials
Write-Host "Step 2: Checking AWS credentials..." -ForegroundColor Yellow
try {
    $identity = aws sts get-caller-identity --output json | ConvertFrom-Json
    Write-Host "✓ AWS credentials valid" -ForegroundColor Green
    Write-Host "  Account: $($identity.Account)" -ForegroundColor Cyan
    Write-Host "  User/Role: $($identity.Arn)" -ForegroundColor Cyan
} catch {
    Write-Host "✗ AWS credentials not configured. Run 'aws configure' first." -ForegroundColor Red
    exit 1
}

Write-Host ""

# Check terraform.tfvars exists
Write-Host "Step 3: Checking terraform.tfvars..." -ForegroundColor Yellow
if (-not (Test-Path "terraform.tfvars")) {
    Write-Host "✗ terraform.tfvars not found. Please create it first:" -ForegroundColor Red
    Write-Host "  Copy terraform.tfvars.example to terraform.tfvars" -ForegroundColor Yellow
    Write-Host "  Edit it with your GitHub credentials" -ForegroundColor Yellow
    exit 1
}
Write-Host "✓ terraform.tfvars found" -ForegroundColor Green

Write-Host ""

# Terraform init
Write-Host "Step 4: Initializing Terraform..." -ForegroundColor Yellow
terraform init
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Terraform init failed" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Terraform initialized" -ForegroundColor Green

Write-Host ""

# Terraform plan
Write-Host "Step 5: Planning Terraform deployment..." -ForegroundColor Yellow
terraform plan -out=tfplan
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Terraform plan failed" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Terraform plan created" -ForegroundColor Green

Write-Host ""

# Terraform apply
Write-Host "Step 6: Applying Terraform configuration..." -ForegroundColor Yellow
Write-Host "This will create AWS resources and may take 5-10 minutes..." -ForegroundColor Cyan
Write-Host ""

terraform apply tfplan
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Terraform apply failed" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Terraform apply complete" -ForegroundColor Green

Write-Host ""

# Get outputs
Write-Host "Step 7: Retrieving deployment outputs..." -ForegroundColor Yellow
$alb_dns = terraform output -raw alb_dns_name
$ecr_uri = terraform output -raw ecr_repository_url
$cluster = terraform output -raw ecs_cluster_name
$service = terraform output -raw ecs_service_name

Write-Host "✓ Outputs retrieved" -ForegroundColor Green

Write-Host ""

# Display results
Write-Host "========================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Access your application:" -ForegroundColor Cyan
Write-Host "  URL: http://$alb_dns" -ForegroundColor White
Write-Host ""
Write-Host "Important resources:" -ForegroundColor Cyan
Write-Host "  ECR Repository: $ecr_uri" -ForegroundColor White
Write-Host "  ECS Cluster: $cluster" -ForegroundColor White
Write-Host "  ECS Service: $service" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Open http://$alb_dns in your browser" -ForegroundColor White
Write-Host "  2. Push code to GitHub to trigger pipeline" -ForegroundColor White
Write-Host "  3. Check pipeline status: aws codepipeline get-pipeline-state --name assignment3-pipeline" -ForegroundColor White
Write-Host ""
Write-Host "View logs:" -ForegroundColor Cyan
Write-Host "  aws logs tail /ecs/assignment3 --follow" -ForegroundColor White
Write-Host "  aws logs tail /aws/codebuild/assignment3 --follow" -ForegroundColor White
Write-Host ""

# Verify ECS is running
Write-Host "Step 8: Verifying ECS service..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

$tasks = aws ecs list-tasks --cluster $cluster --service-name $service --region us-east-1 --output json | ConvertFrom-Json
$taskCount = $tasks.taskArns.Count

if ($taskCount -gt 0) {
    Write-Host "✓ ECS service running with $taskCount task(s)" -ForegroundColor Green
} else {
    Write-Host "⚠ No tasks running yet. They may still be starting..." -ForegroundColor Yellow
    Write-Host "  Check status with: aws ecs describe-services --cluster $cluster --services $service --region us-east-1" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Deployment script complete!" -ForegroundColor Green
