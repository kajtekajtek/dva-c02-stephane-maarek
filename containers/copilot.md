# AWS Copilot - CLI for Containerized Applications

## Overview

AWS Copilot is a command-line interface tool that simplifies building, releasing, and operating containerized applications on AWS. It abstracts infrastructure complexity and provides a developer-friendly experience.

## Purpose and Goals

### The Problem Copilot Solves

Without Copilot, deploying containerized applications requires:

```
1. Create VPC with subnets, security groups, NAT gateways
2. Set up ECS cluster (or EKS cluster)
3. Create IAM roles and policies
4. Configure load balancers
5. Set up DNS and SSL certificates
6. Create ECR repositories
7. Configure auto-scaling policies
8. Set up monitoring and logging
9. Create CI/CD pipeline
10. Configure environment-specific deployments
```

**Typical setup time**: Days to weeks

### With Copilot

```
$ copilot app init my-app
$ copilot env init --name production
$ copilot svc init --name api
$ copilot svc deploy
```

**Setup time**: Minutes

## Core Concepts

### Application

Top-level organization containing all services and environments:

```
my-app (Application)
├── production (Environment)
│   ├── api (Service)
│   ├── web (Service)
│   └── worker (Service)
└── staging (Environment)
    ├── api (Service)
    ├── web (Service)
    └── worker (Service)
```

### Environment

Cluster and networking infrastructure for running services:

```
production (Environment)
├── VPC: 10.0.0.0/16
├── Subnets (2 AZs)
├── Security Groups
├── NAT Gateways
├── Load Balancer
└── ECS Cluster / EKS Cluster
```

**Multiple environments**:
- **production**: High-availability, multi-AZ
- **staging**: Testing environment
- **development**: Individual developer environments

### Service

Containerized application running in an environment:

```
Service: api
├── Image: my-app/api:latest
├── Port: 8080
├── Load Balancer: Application Load Balancer
├── Auto Scaling: 2-10 tasks
├── Health Check: /health
├── Logging: CloudWatch Logs
└── Monitoring: CloudWatch Metrics
```

**Service Types**:
- **Load Balanced Web Service**: HTTP/HTTPS with ALB
- **Backend Service**: Internal communication
- **Scheduled Job**: Cron-based execution
- **Worker Service**: Long-running background tasks

## Copilot Workflow

### 1. Initialize Application

```bash
$ copilot app init my-app
$ ls -la
.copilot/
├── environments/
├── services/
└── addons/
```

Creates `.copilot` directory with application structure.

### 2. Create Environment

```bash
$ copilot env init --name production
✓ Creating environment production
✓ Provisioning VPC, subnets, security groups
✓ Setting up load balancer
✓ Configuring ECS cluster
```

**Environment manifest** (.copilot/environments/production/manifest.yml):

```yaml
name: production
type: load-balanced
network:
  vpc:
    cidr: '10.0.0.0/16'
observability:
  container_insights: true
```

### 3. Create Service

```bash
$ copilot svc init --name api \
  --svc-type 'load-balanced web service' \
  --dockerfile './Dockerfile'

✓ Service created: api
```

**Service manifest** (.copilot/services/api/manifest.yml):

```yaml
name: api
type: load-balanced web service
image:
  build: Dockerfile
  port: 8080
network:
  vpc:
    security_groups:
    - id: sg-12345
variables:
  LOG_LEVEL: INFO
  ENVIRONMENT: production
cpu_units: 256
memory: 512
count: 2
exec: true
logging:
  retention: 30
observability:
  tracing: awsxray
```

### 4. Deploy

```bash
$ copilot svc deploy

✓ Building Docker image
✓ Pushing to ECR
✓ Updating ECS service
✓ Waiting for service to become healthy
✓ Service deployed

Health: Running
Tasks: 2/2 healthy
```

### 5. View Status

```bash
$ copilot svc status

Name: api
Environment: production
Type: Load Balanced Web Service

Desired: 2
Running: 2
Pending: 0

Endpoints:
  https://api.my-app.com
  http://my-app-1234567890.us-east-1.elb.amazonaws.com
```

### 6. View Logs

```bash
$ copilot svc logs --follow

2024-03-30 10:15:23 INFO Server started on port 8080
2024-03-30 10:15:24 INFO Connected to database
2024-03-30 10:15:25 INFO Listening for requests
```

## Architecture Provisioned by Copilot

### What Copilot Creates

When you deploy with Copilot:

```
AWS Account
├── VPC (with subnets, nat gateways)
├── ECS Cluster
│   └── ECS Service
│       ├── Task Definition
│       └── Auto Scaling Group
├── Application Load Balancer
├── ECR Repository
├── CloudWatch Logs
├── CloudWatch Alarms
├── IAM Roles and Policies
├── CodePipeline (optional)
└── Route53 DNS (optional)
```

**Key Infrastructure**:

```
Internet
    ↓
Route53 (DNS)
    ↓
Application Load Balancer
    ↓
ECS Service (Load Balanced)
├── Task: 10.0.1.45:8080
├── Task: 10.0.2.67:8080
└── Auto Scaling: 2-10 tasks
    
Logging & Monitoring:
├── CloudWatch Logs
├── CloudWatch Metrics
├── X-Ray Tracing
└── CloudWatch Alarms
```

## Deploying Multiple Services

### Services Communicating Within Environment

```
Copilot Environment: production

Service: web
├── Public: Load Balanced
├── Port: 80
└── Calls: api-service:8080 (internal DNS)

Service: api
├── Private: Backend service
├── Port: 8080
└── Calls: database, cache

Service: worker
├── Private: Scheduled job
├── Schedule: Every 1 hour
└── Calls: api-service:8080
```

**Service Discovery**:

```bash
# From web service, call api internally
curl http://api:8080/health

# Copilot provides automatic DNS:
# api-service-name.environment-name.local
```

## Environment Configuration

### Environment Manifest

```yaml
name: production
type: load-balanced

network:
  vpc:
    cidr: '10.0.0.0/16'
    nat_gateways: 2
    security_groups:
      ingress:
      - cidr: '0.0.0.0/0'
        ports: 80,443

observability:
  container_insights: true
  
helm_values:
  # For Kubernetes deployments
  replicas: 3
```

### Service Manifest Options

```yaml
name: api
type: load-balanced web service

image:
  build: Dockerfile
  port: 8080
  
variables:
  LOG_LEVEL: INFO
  ENVIRONMENT: production
  
secrets:
  DATABASE_PASSWORD: /copilot/db-password
  API_KEY: /copilot/api-key

cpu_units: 256
memory: 512
count: 2
exec: true

network:
  vpc:
    security_groups:
    - id: sg-12345

logging:
  retention: 30
  splunk_secret: splunk-key

observability:
  tracing: awsxray

scaling:
  min_count: 2
  max_count: 10
  cpu_percentage: 70
  memory_percentage: 80
```

## CI/CD Integration

### Built-in Deployment Pipeline

Copilot can create CodePipeline automatically:

```bash
$ copilot pipeline init --source github \
  --github-repo my-org/my-app \
  --github-branch main
```

**Generated Pipeline**:

```
GitHub Push
    ↓
CodePipeline
    ├── Source: GitHub
    ├── Build: CodeBuild (run tests, build Docker image)
    ├── Push: Push image to ECR
    ├── Deploy to Staging: Run integration tests
    └── Deploy to Production: If approved
```

**Pipeline Manifest** (.copilot/pipelines/main/manifest.yml):

```yaml
name: main
version: 1

triggers:
  - branch: main

stages:
  - name: test
    test_commands:
    - make test
    - make lint
  - name: build
    image_build: api
  - name: staging
    deploy_service:
      environment: staging
  - name: production
    deploy_service:
      environment: production
```

## Multi-Environment Strategy

### Development → Staging → Production

```
Local Development
    ↓
Commit to feature branch
    ↓
CodePipeline: Build & Test (feature branch)
    ↓
Merge to main
    ↓
CodePipeline: Build & Test
    ↓
Auto-deploy to staging
    ↓
Run integration tests
    ↓
Manual approval
    ↓
Deploy to production
```

### Per-Developer Environments

```bash
$ copilot env init --name dev-alice
$ copilot env init --name dev-bob
$ copilot env init --name dev-charlie

Each developer gets isolated environment
with same infrastructure as production
```

## Operations with Copilot

### View Application Status

```bash
# Overall app status
$ copilot app status

# All services across environments
$ copilot svc ls --all

# Specific service
$ copilot svc status --environment production
```

### Scaling

```bash
# Update desired task count
$ copilot svc update --name api \
  --desired-count 5

# Update auto-scaling policy
$ copilot svc update --name api \
  --cpu-percentage 75 \
  --memory-percentage 85
```

### Rolling Back

```bash
# Previous deployment
$ copilot svc rollback --name api

# Specific image version
$ copilot svc deploy --name api \
  --image my-app/api:v1.2.0
```

### Debugging

```bash
# SSH into running container
$ copilot svc exec --name api

# View logs
$ copilot svc logs --name api --follow

# View service details
$ copilot svc describe
```

## Comparison: Copilot vs Manual Deployment

| Task | Manual | Copilot |
|------|--------|---------|
| **VPC Setup** | 30 mins | Automatic |
| **ECS Cluster** | 20 mins | Automatic |
| **Load Balancer** | 20 mins | Automatic |
| **IAM Roles** | 30 mins | Automatic |
| **ECR Repo** | 5 mins | Automatic |
| **Service Deploy** | 20 mins | 2 mins |
| **CI/CD Pipeline** | 2-4 hours | 30 mins |
| **Monitoring Setup** | 1 hour | Automatic |
| **Total Setup Time** | 1-2 days | ~1 hour |
| **Infrastructure Code** | 1000+ lines | 50 lines |

## Use Cases for Copilot

### Ideal Scenarios

1. **New AWS Projects**: Get started quickly with best practices
2. **Microservices**: Multiple services with different scaling needs
3. **Multi-Environment**: Dev, staging, production with same infrastructure
4. **Teams**: Standardized deployment experience across organization
5. **Rapid Iteration**: Focus on application code, not infrastructure

### Less Ideal Scenarios

- Highly custom infrastructure requirements
- Complex multi-region setups (use Terraform)
- Existing infrastructure to migrate
- When you need to understand infrastructure details

## Copilot vs Alternatives

| Tool | Best For | Learning Curve |
|------|----------|-----------------|
| **Copilot** | Quick start, best practices | Low |
| **CloudFormation** | Full control, infrastructure as code | High |
| **Terraform** | Multi-cloud, version control | Medium |
| **Docker Compose** | Local development | Very Low |
| **Kubernetes** | Complex orchestration | Very High |

## References

- AWS. [AWS Copilot Documentation](https://aws.github.io/copilot-cli/)
- AWS. [Copilot GitHub Repository](https://github.com/aws/copilot-cli)
- AWS. [Copilot User Guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service_deployment.html)
- AWS. [Container Infrastructure on AWS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/what-is-amazon-ecs.html)
