# ECS Task Definitions

A task definition is a JSON blueprint that tells ECS how to run a Docker container. Up to **10 containers** can be defined in a single task definition.

## What a Task Definition Contains

- Docker image name (ECR URI or Docker Hub)
- Port bindings (container port → host port)
- CPU and memory requirements
- Environment variables
- Networking configuration
- IAM Task Role
- Logging configuration (e.g., CloudWatch)

---

## IAM Role per Task Definition

Each task definition specifies one task role. Services with different permission needs must use **separate task definitions** with separate roles.

```
Task Definition A → Task Role A (S3 access)   → Service A
Task Definition B → Task Role B (DynamoDB access) → Service B
```

---

## Load Balancing

### EC2 Launch Type — Dynamic Host Port Mapping

When you define only the **container port** (no host port), ECS assigns a random available port on the host. This allows multiple tasks to run on the same EC2 instance even if they all listen on the same container port.

```
EC2 Instance
├── Task → container:80 → host:36789
├── Task → container:80 → host:39586
└── Task → container:80 → host:39748
     ↑
ALB discovers and targets all dynamic ports
```

The EC2 instance Security Group must allow **all TCP ports** from the ALB Security Group (because host ports are unpredictable).

### Fargate — Unique Private IP per Task

Each Fargate task gets its own **ENI with a unique private IP**. No host port concept — only the container port matters.

```
ALB → Target Group
        ├── 172.16.4.5:80  (Task)
        ├── 172.17.35.88:80 (Task)
        └── 172.18.8.192:80 (Task)
```

Security Group on the ENI must allow inbound on the container port from the ALB Security Group.

---

## Environment Variables

Three ways to inject configuration into containers:

| Method | Best for |
|---|---|
| **Hardcoded** in task definition | Non-sensitive values, static URLs |
| **SSM Parameter Store** | Sensitive config (API keys, shared settings) |
| **Secrets Manager** | Sensitive secrets (DB passwords, credentials) |

For bulk configuration, reference an `.env` file stored in **S3** via `environmentFiles`:

```json
"environmentFiles": [
  { "value": "arn:aws:s3:::my-bucket/prod.env", "type": "s3" }
]
```

The task execution role needs permission to read from SSM, Secrets Manager, or S3 depending on which methods are used.

---

## Data Volumes — Bind Mounts

Bind mounts let multiple containers within the same task share a filesystem path. Useful for the **sidecar pattern** — a secondary container that reads application output (logs, metrics) and ships it elsewhere.

| Launch type | Storage backend | Lifecycle |
|---|---|---|
| EC2 | EC2 instance storage | Tied to the EC2 instance |
| Fargate | Ephemeral task storage (20–200 GiB) | Tied to the task |

```
Task
├── App container    → writes to /var/logs/ (bind mount)
└── Sidecar container → reads from /var/logs/ → ships to CloudWatch / Datadog
```

The bind mount is declared as a volume in the task definition and mounted into each container at the desired path.

---

## Task Placement *(EC2 launch type only)*

When a new task needs to start, ECS must choose which EC2 instance to place it on. Fargate handles this automatically and does not support placement configuration.

### Selection Process

ECS filters and selects instances in this order:

1. Instances that satisfy CPU, memory, and port requirements
2. Instances that satisfy placement **constraints**
3. Instances that satisfy placement **strategies**
4. Final instance selected

### Strategies

Strategies are **best-effort** — ECS tries to follow them but will fall back if needed.

**Binpack** — pack tasks onto as few instances as possible to minimize cost:

```json
{ "type": "binpack", "field": "memory" }
```

```
Instance A: [Task][Task][Task]   ← packed
Instance B: (empty)              ← not used yet
```

**Random** — place tasks on instances randomly:

```json
{ "type": "random" }
```

**Spread** — distribute tasks evenly across a specified attribute (e.g., AZ):

```json
{ "type": "spread", "field": "attribute:ecs.availability-zone" }
```

```
us-east-1a: [Task][Task]
us-east-1b: [Task][Task]
us-east-1c: [Task][Task]
```

Strategies can be **combined** — e.g., spread by AZ first, then binpack by memory within each AZ.

### Constraints

Constraints are **hard requirements** — tasks will not be placed if they cannot be satisfied.

**`distinctInstance`** — each task must run on a different EC2 instance:

```json
{ "type": "distinctInstance" }
```

**`memberOf`** — tasks only placed on instances matching an expression (uses Cluster Query Language):

```json
{ "type": "memberOf", "expression": "attribute:ecs.instance-type =~ t3.*" }
```

---

## References

- [ECS Task Definitions](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html)
- [ECS Task Placement](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-placement.html)
- [ECS Environment Variables](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/taskdef-envfiles.html)
- [ECS Bind Mounts](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/bind-mounts.html)
