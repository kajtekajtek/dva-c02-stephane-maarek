# Amazon EKS - Elastic Kubernetes Service

## Overview

Amazon EKS (Elastic Kubernetes Service) is AWS's managed Kubernetes service. It runs Kubernetes control plane and allows you to deploy containerized applications using Kubernetes orchestration.

## When to Use EKS

### EKS vs ECS

| Factor | ECS | EKS |
|--------|-----|-----|
| **Learning Curve** | Easier (AWS-native) | Steeper (Kubernetes) |
| **Ecosystem** | AWS services | Kubernetes ecosystem |
| **Vendor Lock-in** | AWS-specific | Cloud-agnostic |
| **Community** | AWS community | Larger open-source |
| **Migration** | Lift-and-shift from other platforms | Lift-and-shift Kubernetes clusters |
| **Complexity** | Lower | Higher (more powerful) |

### Use EKS When

- Your team already uses Kubernetes on-premises or in another cloud
- You need Kubernetes-specific features (DaemonSets, StatefulSets, etc.)
- You want cloud-agnostic containerization
- You need advanced orchestration capabilities
- You're migrating from existing Kubernetes clusters

### Use ECS When

- You're new to containerization
- You want simpler AWS-native solution
- You prefer AWS integration and support
- You're building new containerized applications

## Kubernetes Architecture

### Core Components

```
┌─────────────────────────────────────────┐
│ Kubernetes Cluster                      │
├─────────────────────────────────────────┤
│                                         │
│ Control Plane (AWS managed in EKS):     │
│ ├── API Server                          │
│ ├── Scheduler                           │
│ ├── Controller Manager                  │
│ └── etcd (state database)               │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│ Worker Nodes (you manage):              │
│ ├── Node 1 (EC2 instance)               │
│ │   └── Pods (containers)               │
│ ├── Node 2 (EC2 instance)               │
│ │   └── Pods (containers)               │
│ └── Node 3 (Fargate)                    │
│     └── Pods (containers)               │
│                                         │
└─────────────────────────────────────────┘
```

### Key Kubernetes Concepts

**Pod**: Smallest deployable unit, usually one container
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
spec:
  containers:
  - name: myapp
    image: myapp:latest
    ports:
    - containerPort: 8080
```

**Deployment**: Manages Pods with desired state, replicas, updates
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: myapp:latest
        ports:
        - containerPort: 8080
```

**Service**: Exposes Pods through stable IP/DNS
```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  type: LoadBalancer
  selector:
    app: myapp
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
```

## Amazon EKS Architecture

### Managed Control Plane

AWS manages the Kubernetes control plane:

```
┌────────────────────────────────────┐
│ AWS Managed (EKS)                  │
├────────────────────────────────────┤
│ Control Plane                      │
│ - Kubernetes API Server            │
│ - Scheduler                        │
│ - Controller Manager               │
│ - etcd                             │
│                                    │
│ (High availability across 3 AZs)   │
└────────────────────────────────────┘
         ↓
Your VPC
├── Public Subnets
│   └── Load Balancer / API Gateway
├── Private Subnets
│   ├── Worker Node 1 (EC2)
│   ├── Worker Node 2 (EC2)
│   ├── Worker Node 3 (EC2)
│   └── Fargate (serverless)
└── Auto Scaling Group
```

**Benefits**:
- High availability (multi-AZ)
- Automatic patching and updates
- AWS manages security
- Pay only for worker nodes and resources

### Cluster Architecture Diagram

```
Internet
    ↓
AWS Elastic Load Balancer
    ↓
Application Load Balancer (optional)
    ↓
VPC
├── Public Subnet 1
│   └── NAT Gateway
├── Private Subnet 1 (AZ 1)
│   ├── EKS Node 1 (EC2)
│   │   └── Pods
│   └── EKS Node 2 (EC2)
│       └── Pods
├── Private Subnet 2 (AZ 2)
│   ├── EKS Node 3 (EC2)
│   │   └── Pods
│   └── Fargate Pod
└── EKS Control Plane (managed, multi-AZ)
    ├── API Server
    ├── Scheduler
    └── etcd
```

## Worker Node Types

### Managed Node Groups

AWS creates and manages EC2 instances for you:

```
┌─────────────────────────────────────┐
│ AWS Managed Node Group              │
├─────────────────────────────────────┤
│                                     │
│ ├── EC2 Instance 1 (t3.medium)     │
│ ├── EC2 Instance 2 (t3.medium)     │
│ └── EC2 Instance 3 (t3.medium)     │
│                                     │
│ Backed by Auto Scaling Group        │
│ ├── Min: 1                          │
│ ├── Desired: 3                      │
│ └── Max: 10                         │
│                                     │
│ Support: On-Demand or Spot          │
│                                     │
└─────────────────────────────────────┘
```

**Configuration**:

```
Node Group: production
├── Instance Types: t3.medium, t3.large
├── Desired Capacity: 3
├── Min: 1, Max: 10
├── Capacity Type: On-Demand
├── Disk: 20 GB gp3
└── IAM Role: eksNodeRole
```

**Advantages**:
- AWS handles AMI selection, updates, scaling
- Simpler than self-managed nodes
- Automatic health checks and replacement

### Self-Managed Nodes

You provision and manage EC2 instances:

```
┌─────────────────────────────────────┐
│ Your Managed Node Group             │
├─────────────────────────────────────┤
│                                     │
│ Use EKS-optimized AMI:              │
│ - Pre-configured for Kubernetes     │
│ - Includes kubelet and container    │
│ - Runtime pre-installed             │
│                                     │
│ You manage:                         │
│ ├── Launch template                 │
│ ├── Auto Scaling Group              │
│ ├── Patches and updates             │
│ └── Capacity planning               │
│                                     │
└─────────────────────────────────────┘
```

**When to Use**:
- Need custom AMI
- Specific Kubernetes versions
- Complex infrastructure requirements

### AWS Fargate with EKS

Serverless pod execution:

```
┌─────────────────────────────────────┐
│ Fargate (Serverless)                │
├─────────────────────────────────────┤
│                                     │
│ Deploy Pods without managing nodes  │
│ - No EC2 instances to manage        │
│ - Automatic scaling                 │
│ - Pay per pod second                │
│                                     │
│ Configuration:                      │
│ ├── Fargate Profile                 │
│ │   └── Subnets & Security Groups   │
│ └── Pod Namespace (automatic)       │
│                                     │
└─────────────────────────────────────┘
```

**When to Use**:
- Variable workloads
- Simplicity over cost
- Serverless preference
- Temporary job runners

## EKS Storage

### StorageClass and Persistent Volumes

Kubernetes abstraction for storage:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-storage
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  storageClassName: ebs-storage
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
```

### Container Storage Interface (CSI) Drivers

AWS provides CSI drivers for storage integration:

```
EKS Cluster
├── EBS CSI Driver
│   └── Enables: AWS EBS volumes
├── EFS CSI Driver
│   └── Enables: AWS EFS shared storage
├── FSx for Lustre CSI
│   └── Enables: High-performance HPC storage
└── FSx for NetApp ONTAP CSI
    └── Enables: Enterprise storage
```

### Supported Storage Options

| Storage | Use Case | Multi-Pod Access | Persistent |
|---------|----------|------------------|------------|
| **EBS** | Single-pod persistent storage | No | Yes |
| **EFS** | Multi-pod shared storage | Yes | Yes |
| **FSx for Lustre** | High-performance computing | Yes | Yes |
| **FSx for NetApp** | Enterprise workloads | Yes | Yes |
| **S3** | Large object storage | Yes | Yes |

## EKS Networking

### VPC Configuration

```
VPC (10.0.0.0/16)
├── Public Subnets (2 AZs)
│   ├── 10.0.0.0/24 (AZ a)
│   │   └── NAT Gateway
│   └── 10.0.1.0/24 (AZ b)
│       └── NAT Gateway
├── Private Subnets (3 AZs)
│   ├── 10.0.10.0/24 (AZ a) ← EKS Nodes
│   ├── 10.0.11.0/24 (AZ b) ← EKS Nodes
│   └── 10.0.12.0/24 (AZ c) ← EKS Nodes
└── Control Plane (Managed)
```

### Pod Networking

Each pod gets unique IP from VPC CIDR:

```
Pod 1: 10.0.10.5 (Subnet a)
Pod 2: 10.0.10.6 (Subnet a)
Pod 3: 10.0.11.7 (Subnet b)
Pod 4: 10.0.12.8 (Subnet c)

All pods can communicate directly using IP
(no port mapping needed)
```

### Service Types

```yaml
kind: Service
metadata:
  name: myapp
spec:
  type: LoadBalancer  # Creates AWS ALB
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: myapp
```

## EKS Monitoring and Logging

### CloudWatch Container Insights

Collect logs and metrics from EKS:

```
EKS Cluster
├── Metrics
│   ├── Pod CPU/Memory
│   ├── Node CPU/Memory
│   └── Container Insights dashboard
├── Logs
│   ├── Application logs
│   ├── Worker node logs
│   └── Kubernetes component logs
└── CloudWatch Logs
    └── Log groups by namespace
```

**Enable Container Insights**:

```bash
aws eks update-cluster-logging \
  --cluster-name my-cluster \
  --logging-config '[{
    "clusterLogging": [{
      "enabled": true,
      "types": ["api", "audit", "authenticator", "controllerManager", "scheduler"]
    }],
    "resourceId": "my-cluster"
  }]'
```

### CloudWatch Logs

EKS automatically sends control plane logs:

```
/aws/eks/my-cluster/cluster
├── api
├── audit
├── authenticator
├── controllerManager
└── scheduler
```

## Multi-Region EKS Deployment

For high availability across regions:

```
Region 1 (us-east-1)
└── EKS Cluster
    ├── Node Group (AZ a)
    ├── Node Group (AZ b)
    └── Node Group (AZ c)

Region 2 (us-west-2)
└── EKS Cluster
    ├── Node Group (AZ a)
    ├── Node Group (AZ b)
    └── Node Group (AZ c)

Global Load Balancer / Route53
├── Route to Region 1 (primary)
└── Route to Region 2 (failover)
```

## Comparison: ECS vs EKS

### ECS Strengths

- Native AWS integration
- Simpler to set up
- Lower learning curve
- AWS support out of the box
- Perfect for AWS-only deployments

### EKS Strengths

- Cloud-agnostic (portable)
- Larger ecosystem
- Advanced orchestration
- Kubernetes standard
- Easy multi-cloud strategy

## References

- AWS. [Amazon EKS Documentation](https://docs.aws.amazon.com/eks/)
- AWS. [EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- AWS. [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- Kubernetes. [Official Documentation](https://kubernetes.io/docs/)
- AWS. [EKS Storage](https://docs.aws.amazon.com/eks/latest/userguide/storage.html)
