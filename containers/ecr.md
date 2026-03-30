# Amazon ECR - Elastic Container Registry

## Overview

Amazon Elastic Container Registry (ECR) is AWS's managed Docker container image registry. It provides a secure, scalable, and reliable way to store, manage, and deploy Docker container images.

## What is Amazon ECR?

### Core Features

- **Private Repository**: Store proprietary container images securely within your AWS account
- **Public Repository**: Share images through Amazon ECR Public Gallery (gallery.ecr.aws)
- **AWS Integration**: Seamlessly integrated with ECS, EKS, and Lambda
- **S3-Backed Storage**: Images stored on Amazon S3 for durability and availability
- **IAM-Controlled Access**: Fine-grained permissions using AWS Identity and Access Management

### Image Management Capabilities

- **Versioning**: Multiple versions of the same image using tags
- **Image Tagging**: Organize images with semantic tags (e.g., `latest`, `v1.2.0`, `prod`, `staging`)
- **Image Lifecycle Policies**: Automatically delete old or unused images based on rules
- **Vulnerability Scanning**: Integrated with Amazon Inspector to identify security vulnerabilities
- **Encryption**: Images encrypted at rest using KMS (AWS Key Management Service)

## Registry Types

### Private Repository

**Best for**: Proprietary applications and internal use

**Characteristics**:
- Images stored in your AWS account
- Access controlled via IAM policies
- Fully isolated from other AWS accounts
- Recommended for production workloads

**Typical Workflow**:
1. Developer builds Docker image locally
2. Pushes image to private ECR repository
3. ECS/EKS retrieves image securely for deployment

### Public Repository (ECR Public Gallery)

**Best for**: Open-source projects and shared libraries

**Characteristics**:
- Images accessible to anyone with the URI
- Free tier available
- Images automatically mirrored for global availability
- Requires authorization only for pushing

**URL**: https://gallery.ecr.aws

## Repository Structure

```
AWS Account
│
└── Amazon ECR
    │
    ├── Private Repository: myapp
    │   ├── Image: myapp:latest
    │   ├── Image: myapp:v1.2.0
    │   └── Image: myapp:staging
    │
    └── Private Repository: backend-service
        ├── Image: backend-service:latest
        └── Image: backend-service:v2.1.0
```

## Authentication and Access

### Login Process

To authenticate with ECR, obtain an authorization token:

```bash
# Get login password and authenticate with Docker CLI
aws ecr get-login-password --region us-east-1 | docker login \
  --username AWS \
  --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
```

### IAM Permissions

**Required Policy for pushing/pulling images**:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ],
      "Resource": "arn:aws:ecr:us-east-1:123456789012:repository/myapp"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "arn:aws:ecr:us-east-1:123456789012:repository/myapp"
    }
  ]
}
```

**Troubleshooting**: If image pull/push fails, verify IAM policy is attached to the EC2 instance role.

## Docker CLI Commands

### Authentication

```bash
# Login to ECR
aws ecr get-login-password --region region | docker login \
  --username AWS --password-stdin account-id.dkr.ecr.region.amazonaws.com
```

### Pushing Images

```bash
# Tag local image for ECR
docker tag myapp:latest account-id.dkr.ecr.region.amazonaws.com/myapp:latest

# Push to ECR
docker push account-id.dkr.ecr.region.amazonaws.com/myapp:latest

# Push with version tag
docker tag myapp:v1.2.0 account-id.dkr.ecr.region.amazonaws.com/myapp:v1.2.0
docker push account-id.dkr.ecr.region.amazonaws.com/myapp:v1.2.0
```

### Pulling Images

```bash
# Pull from ECR
docker pull account-id.dkr.ecr.region.amazonaws.com/myapp:latest

# Pull specific version
docker pull account-id.dkr.ecr.region.amazonaws.com/myapp:v1.2.0
```

## Image Lifecycle Policies

### Purpose

Automatically manage image lifecycle to reduce storage costs and maintain security by removing outdated images.

### Example Policy

```json
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 10 images with 'prod' tag",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["prod"],
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 2,
      "description": "Remove untagged images older than 7 days",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 7
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
```

## Image Vulnerability Scanning

### Basic Scanning

When you push an image to ECR, it can be scanned for known vulnerabilities using Amazon Inspector.

```bash
# Enable scanning on push (AWS Console or CLI)
aws ecr put-image-scanning-configuration \
  --repository-name myapp \
  --image-scanning-configuration scanOnPush=true
```

### Scan Results

Vulnerabilities are classified by severity:
- **CRITICAL**: Immediate action required
- **HIGH**: Address urgently
- **MEDIUM**: Plan remediation
- **LOW**: Monitor and update when convenient
- **INFORMATIONAL**: No immediate action needed

## Cost Optimization

### Pricing Model

- **Storage**: Per GB per month for stored images
- **Data Transfer**: Egress to internet (transfer from ECR to external networks)
- **Public ECR**: Free for public repositories

### Strategies to Reduce Costs

1. **Implement Lifecycle Policies**: Automatically delete outdated images
2. **Use Image Tags**: Keep only necessary versions (e.g., `latest` and `v1.2.3`)
3. **Layer Reuse**: Build images that share common layers to reduce duplicate storage
4. **Compress Images**: Use minimal base images (e.g., `alpine` instead of `ubuntu`)

## Integration with ECS/EKS

### Image URI Format

ECR images are referenced by full URI:

```
123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:v1.2.0
                    ↓                          ↓           ↓
              AWS Account ID              Repository   Image Tag
```

### ECS Task Definition Reference

```json
{
  "name": "myapp",
  "image": "123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:latest",
  "memory": 512,
  "cpu": 256
}
```

### EKS Deployment Reference

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: myapp
    image: 123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
```

## Security Best Practices

1. **Use Private Repositories**: Store proprietary images in private repositories
2. **Enable Image Scanning**: Detect vulnerabilities automatically
3. **Implement Lifecycle Policies**: Remove outdated images
4. **Use IAM Roles**: Grant least-privilege access through IAM policies
5. **Encrypt Images**: Leverage KMS encryption at rest
6. **Enable Access Logging**: Monitor who accesses images
7. **Use Image Signing**: Verify image authenticity (Docker Content Trust)
8. **Regular Updates**: Keep base images current with security patches

## References

- AWS. [Amazon ECR Documentation](https://docs.aws.amazon.com/ECR/)
- AWS. [Amazon ECR User Guide](https://docs.aws.amazon.com/AmazonECR/latest/userguide/)
- AWS. [ECR Image Scanning](https://docs.aws.amazon.com/AmazonECR/latest/userguide/image-scanning.html)
- AWS. [ECR Lifecycle Policies](https://docs.aws.amazon.com/AmazonECR/latest/userguide/LifecyclePolicies.html)
