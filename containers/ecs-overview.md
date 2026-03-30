# Amazon ECS

ECS (Elastic Container Service) is AWS's native container orchestration service. It runs Docker containers as **tasks** grouped in **clusters**, and manages their lifecycle.

## Launch Types

### EC2

- You provision and maintain EC2 instances. 
- Each instance must run the **ECS Agent** to register with the cluster. 
- AWS handles starting and stopping containers, but infrastructure is your responsibility.

```
ECS Cluster
├── EC2 Instance (ECS Agent) → runs tasks
├── EC2 Instance (ECS Agent) → runs tasks
└── EC2 Instance (ECS Agent) → runs tasks
```

### Fargate

- No EC2 instances to manage — fully serverless. 
- You only create task definitions; AWS provisions infrastructure based on CPU/RAM requirements. 
- To scale, increase the number of tasks.

```
ECS Cluster (Fargate)
└── AWS provisions compute per task automatically
```

### EC2 vs Fargate

| | EC2 | Fargate |
|---|---|---|
| Infrastructure | You manage | AWS manages |
| Scaling | Tasks + instances | Tasks only |
| Cost | Lower for steady load | Pay per vCPU-hour + GB-hour (1 min minimum) |
| Control | Full (OS, instance type, capacity) | Task-level (CPU, memory, networking, IAM) |
| Best for | Predictable, cost-sensitive | Variable load, simplicity |

---

## IAM Roles

Two separate roles are needed — one for the **agent**, one for the **application**.

### EC2 Instance Profile *(EC2 launch type only)*

Used by the ECS Agent on the EC2 instance to interact with AWS on your behalf:
- Pull images from ECR
- Write container logs to CloudWatch Logs
- Make API calls to the ECS service
- Read secrets from Secrets Manager / SSM Parameter Store

### ECS Task Role

Defined in the task definition. Grants the **container application** permissions to call AWS services:
- Read/write S3
- Query DynamoDB
- Invoke Lambda, publish to SNS, etc.

Each ECS Service should use a **different task role** scoped to what that service actually needs.

```
EC2 Instance
├── ECS Agent → uses EC2 Instance Profile (pull images, send logs)
├── Task A    → uses Task Role A (access S3)
└── Task B    → uses Task Role B (access DynamoDB)
```

---

## Load Balancer Integrations

| Load Balancer | When to use |
|---|---|
| **ALB** (Application) | Most use cases — HTTP/HTTPS, path routing, dynamic port mapping |
| **NLB** (Network) | High throughput, low latency, or AWS PrivateLink |
| **CLB** (Classic) | Not recommended — no Fargate support, no advanced features |

ALB is the standard choice for ECS services.

---

## Data Volumes — EFS

EFS (Elastic File System) can be mounted directly into ECS tasks. Useful when tasks across multiple AZs need to share persistent data.

- Works with both EC2 and Fargate
- Tasks in any AZ access the same filesystem
- Fargate + EFS = fully serverless persistent storage
- **S3 cannot be mounted as a filesystem** (use SDK instead)

---

## ECS Service Auto Scaling

ECS uses **AWS Application Auto Scaling** to adjust the number of running tasks. Scaling operates at the **task level** — distinct from EC2 Auto Scaling at the instance level.

### Metrics

- ECS Service Average CPU Utilization
- ECS Service Average Memory Utilization
- ALB Request Count Per Target

### Policies

| Policy | How it works |
|---|---|
| **Target Tracking** | Keeps a CloudWatch metric at a target value |
| **Step Scaling** | Adds/removes tasks when a CloudWatch alarm fires |
| **Scheduled Scaling** | Changes capacity at a scheduled time/date |

Fargate auto scaling is simpler — no need to manage instance capacity underneath.

### EC2 Instance Scaling *(EC2 launch type only)*

When tasks can't be placed due to insufficient capacity, EC2 instances need to scale too.

**Auto Scaling Group (ASG):** Scale instances based on CPU utilization. Blunt instrument — doesn't know about ECS task demand directly.

**Capacity Provider (recommended):** Paired with an ASG. ECS automatically provisions EC2 instances when tasks are pending due to insufficient CPU/RAM. More precise than raw ASG scaling.

```
Task count ↑ → not enough EC2 capacity
→ Capacity Provider adds EC2 instances
→ Pending tasks get scheduled
```

---

## Rolling Updates

When updating a service from v1 to v2, two parameters control the rollout:

| Parameter | Meaning |
|---|---|
| **Minimum Healthy Percent** | Minimum % of desired tasks that must stay running during update |
| **Maximum Percent** | Maximum % of desired tasks (old + new) allowed at once |

### Min 50%, Max 100%

Stops half the old tasks, starts new ones to replace them. Lower resource overhead, brief capacity reduction.

```
Step 1: [v1][v1][v1][v1]  →  Step 2: [v1][v1][v2][v2]  →  Step 3: [v2][v2][v2][v2]
```

### Min 100%, Max 150%

Starts new tasks alongside old ones before terminating any. Slower but no capacity loss.

```
Step 1: [v1][v1][v1][v1]  →  Step 2: [v1][v1][v1][v1][v2][v2]  →  Step 3: [v2][v2][v2][v2]
```

---

## Event-Driven Patterns

### EventBridge — Trigger on Event

Run a Fargate task in response to an AWS event (e.g., S3 object uploaded):

```
S3 Upload → EventBridge Rule → Fargate Task
                                └── Task Role → read S3, write DynamoDB
```

### EventBridge — Scheduled Tasks

Run tasks on a schedule (cron-style):

```
EventBridge Schedule (every 1 hour) → Fargate Task → process S3 data
```

### SQS Queue Integration

ECS Service polls an SQS queue and auto-scales tasks based on queue depth:

```
Messages → SQS Queue
              ↑ poll
         [Task][Task][Task]
         ECS Service Auto Scaling (scales with queue depth)
```

### Intercept Stopped Tasks

Detect container exits via EventBridge to trigger alerts or remediation:

```
ECS Task exits → EventBridge Event Pattern → SNS → email to admin
```

---

## References

- [Amazon ECS Developer Guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/)
- [ECS Auto Scaling](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-auto-scaling.html)
- [ECS Capacity Providers](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-capacity-providers.html)
- [EFS Volumes in ECS](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/efs-volumes.html)
