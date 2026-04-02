# Elastic Beanstalk — Overview

A developer-centric PaaS for deploying applications on AWS. It provisions and manages EC2, ASG, ELB, RDS, CloudWatch, etc. under the hood using CloudFormation. You upload your code — Beanstalk handles the rest.

- Free service; you only pay for the underlying resources [1]
- Full control over configuration is retained
- Supports Go, Java SE, Java/Tomcat, .NET (Linux & Windows), Node.js, PHP, Python, Ruby, Packer, Docker (single & multi-container), and preconfigured Docker [1]

---

## Core Concepts

**Application** — top-level container. Holds environments, versions, and configurations.

**Application Version** — a labeled iteration of deployable code (zip in S3). A single application can have up to 1000 versions; use lifecycle policies to clean up old ones.

**Environment** — a collection of AWS resources running one application version at a time. You can have multiple environments per application (dev, staging, prod).

**Workflow:**

```
Create Application → Upload Version → Launch Environment → Manage / Deploy new versions
```

---

## Environment Tiers

### Web Server Tier

Serves HTTP requests. Architecture:

```
Internet → ELB → ASG → EC2 instances (web server)
```

- ELB distributes traffic across instances
- ASG handles scaling
- Standard web application setup

### Worker Tier

Processes background jobs from an SQS queue. Architecture:

```
SQS Queue → sqsd daemon on EC2 → HTTP POST to localhost → your app processes the message
```

- Beanstalk creates and manages the SQS queue
- A daemon (`sqsd`) on each instance polls the queue and forwards messages to `localhost:80` as HTTP POST requests
- Scales based on the number of SQS messages in the queue
- Supports periodic tasks via `cron.yaml` in the source bundle root [3]:

```yaml
version: 1
cron:
  - name: "cleanup"
    url: "/tasks/cleanup"
    schedule: "0 */12 * * *"
```

- The daemon posts to the URL on schedule — your app handles it like any other request
- Failed messages can be routed to a **dead letter queue** to avoid infinite retry loops
- Web tier environments can push messages to the worker queue for async processing

---

## Deployment Modes

### Single Instance

One EC2 instance with an Elastic IP. No load balancer. Good for development.

```
Elastic IP → EC2 Instance → (optional) RDS
```

### High Availability

Multiple instances behind a load balancer in multiple AZs. Good for production.

```
ALB → ASG (multi-AZ) → EC2 instances → RDS (Multi-AZ)
```

---

## Deployment Policies

Six strategies for updating application code. The choice depends on the tolerance for downtime, cost overhead, and rollback speed.

### All at Once

Deploys to **all instances simultaneously**. Fastest, but causes downtime while instances restart with the new version.

- Downtime: **yes**
- Capacity during deploy: **zero** (briefly)
- Rollback: manual redeploy of previous version
- Additional cost: none
- Best for: dev environments, quick iterations

### Rolling

Updates instances in **batches** (configurable bucket size). Old version serves traffic while batches are updated one at a time.

- Downtime: **no**
- Capacity during deploy: **reduced** (by one batch)
- Both versions run simultaneously during rollout
- Rollback: manual redeploy
- Additional cost: none
- Best for: cost-sensitive environments tolerant of reduced capacity

### Rolling with Additional Batches

Launches a **new batch of instances first**, then performs rolling updates. Maintains full capacity throughout because the extra batch compensates for the one being updated.

- Downtime: **no**
- Capacity during deploy: **full** (maintained)
- Both versions run simultaneously during rollout
- Rollback: manual redeploy
- Additional cost: **small** (temporary extra batch)
- Best for: production when capacity cannot drop

### Immutable

Launches a **full set of new instances in a temporary ASG** running the new version. After health checks pass, the new instances are moved to the original ASG and old instances are terminated.

- Downtime: **no**
- Capacity during deploy: **doubled** temporarily
- Rollback: **fast** — just terminate the temporary ASG
- Additional cost: **high** (double capacity)
- Best for: production when fast rollback is critical

### Blue / Green

Not a native Beanstalk deployment policy — it's a manual pattern using two separate environments [1]:

1. Create a new environment ("green") with v2
2. Validate green independently
3. Use Route 53 weighted routing to shift traffic gradually
4. When ready, **swap environment URLs** (CNAME swap) in Beanstalk
5. Terminate old ("blue") environment

- Downtime: **no**
- Rollback: swap URLs back
- Additional cost: full duplicate environment during transition

### Traffic Splitting

Canary testing built into Beanstalk [1]. New instances are created in a **temporary ASG**, and a configurable percentage of traffic is routed to them for an evaluation period.

- Downtime: **no**
- A small % of traffic hits the new version via ALB
- Health is monitored automatically during the evaluation window
- If health checks fail → **automated rollback** (very fast)
- After evaluation passes → new instances migrate to the original ASG, old instances are terminated
- Best for: production when you want automated canary validation

### Summary Table

| Policy | Downtime | Capacity | Rollback | Cost | Deploy Speed |
|---|---|---|---|---|---|
| All at once | Yes | Zero (briefly) | Manual | None | Fastest |
| Rolling | No | Reduced | Manual | None | Slow |
| Rolling + batch | No | Full | Manual | Small | Slower |
| Immutable | No | Doubled | Fast (terminate ASG) | High | Slow |
| Blue/Green | No | Doubled | Swap URLs | High | Manual |
| Traffic splitting | No | Doubled | Automatic | High | Slow |

---

## Deployment Process

1. Describe dependencies in platform-specific file (`requirements.txt`, `package.json`, `Gemfile`, etc.)
2. Package application code as a **zip file**
3. Upload via Console (creates new application version) or via CLI (`eb deploy`)
4. Beanstalk deploys the zip to each EC2 instance, resolves dependencies, and starts the application

---

## EB CLI

An optional CLI that simplifies Beanstalk workflows. Useful for scripting and CI/CD pipelines.

Key commands:

| Command | Purpose |
|---|---|
| `eb create` | Create a new environment |
| `eb deploy` | Deploy current code to environment |
| `eb open` | Open environment URL in browser |
| `eb status` | Show environment status |
| `eb health` | Show instance health |
| `eb logs` | Retrieve logs |
| `eb config` | Edit environment configuration |
| `eb terminate` | Delete environment |
| `eb events` | Show recent events |

---

## References

1. [Elastic Beanstalk Developer Guide](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/)
2. [Deployment Policies and Settings](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features.rolling-version-deploy.html)
3. [Worker Environments](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/using-features-managing-env-tiers.html)
