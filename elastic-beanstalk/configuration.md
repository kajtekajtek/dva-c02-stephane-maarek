# Elastic Beanstalk — Configuration and Migrations

## Lifecycle Policy

Beanstalk can store at most **1000 application versions**. Once the limit is reached, new deployments fail. Use lifecycle policies to automatically remove old versions.

Removal criteria (one or both):

| Criteria | Description |
|---|---|
| **Time-based** | Delete versions older than N days |
| **Count-based** | Keep at most N versions, delete the rest |

- Versions currently deployed to an environment are never deleted
- Option to retain the source bundle in S3 even when the version record is deleted (prevents data loss)

---

## .ebextensions

All configuration that can be set in the Console can also be declared as code in `.ebextensions/` files shipped with your application zip.

**Requirements:**
- Files must be in the `.ebextensions/` directory at the root of the source bundle
- YAML or JSON format
- File extension must be `.config` (e.g., `logging.config`, `scaling.config`)

**Capabilities:**
- Modify default settings via `option_settings`
- Provision additional AWS resources (RDS, ElastiCache, DynamoDB, S3, SQS, etc.)
- Run custom commands during deployment
- Configure instance software and packages

**Example — setting environment variables and scaling:**

```yaml
# .ebextensions/env.config
option_settings:
  aws:elasticbeanstalk:application:environment:
    NODE_ENV: production
    LOG_LEVEL: info

  aws:autoscaling:asg:
    MinSize: 2
    MaxSize: 8
```

**Example — provisioning a DynamoDB table:**

```yaml
# .ebextensions/dynamodb.config
Resources:
  SessionTable:
    Type: AWS::DynamoDB::Table
    Properties:
      TableName: sessions
      AttributeDefinitions:
        - AttributeName: id
          AttributeType: S
      KeySchema:
        - AttributeName: id
          KeyType: HASH
      BillingMode: PAY_PER_REQUEST
```

**Important:** Resources created via `.ebextensions` are part of the environment's CloudFormation stack. They are **deleted when the environment is terminated** [1].

### Platform Hooks (Modern Alternative)

For Amazon Linux 2 / Amazon Linux 2023, AWS recommends **platform hooks** over `.ebextensions` for custom scripts [2]. Hooks are shell scripts placed in `.platform/hooks/`:

| Hook Directory | When it runs |
|---|---|
| `.platform/hooks/prebuild/` | After source extraction, before platform setup |
| `.platform/hooks/predeploy/` | After app/server config, before final deployment |
| `.platform/hooks/postdeploy/` | After deployment completes (final step) |

Scripts must be executable. They run in alphabetical order.

**Buildfile** and **Procfile** (placed in the source root) provide a simpler alternative for build commands and long-running processes:

| File | Purpose | Lifecycle |
|---|---|---|
| `Buildfile` | Short-running build commands (e.g., compile) | Terminates after execution |
| `Procfile` | Long-running app processes | Monitored and restarted if they exit |

`.ebextensions` is still required for anything that needs CloudFormation resource references or `option_settings`.

---

## Under the Hood — CloudFormation

Beanstalk environments are backed by **CloudFormation stacks**. Every resource (ASG, ELB, SG, RDS, etc.) is a CloudFormation resource.

This means:
- You can define additional CloudFormation resources in `.ebextensions`
- Environment deletion = CloudFormation stack deletion = all managed resources deleted
- You can inspect the stack in the CloudFormation console to see exactly what Beanstalk created

---

## Cloning

Clone an existing environment to create an identical copy. Preserves:

- Load balancer type and configuration
- ASG settings
- RDS database type (**data is not copied**)
- Environment variables
- All other configuration

Useful for creating a test environment from production. Settings can be changed after cloning.

---

## Migrations

### Changing Load Balancer Type

You **cannot change the load balancer type** on an existing environment (e.g., CLB → ALB). Only the configuration can be modified.

**Migration steps:**

1. Create a **new environment** with the desired LB type (cannot use clone — clone preserves LB type)
2. Deploy your application to the new environment
3. Redirect traffic via **CNAME swap** or **Route 53 update**
4. Terminate the old environment

```
Old env (CLB) ──── CNAME swap ───→ New env (ALB)
                  or Route 53
```

### Decoupling RDS from Beanstalk

Beanstalk can provision RDS as part of the environment. This is convenient for dev/test but **dangerous for production** — terminating the environment **deletes the database**.

**For production:** create RDS independently and pass the connection string to Beanstalk via environment variables.

**Migration steps to decouple an existing RDS:**

1. Create a **snapshot** of the RDS database (safeguard)
2. Enable **deletion protection** on the RDS instance in the RDS console
3. Create a **new Beanstalk environment** without RDS, configured to point at the existing database
4. Perform a **CNAME swap** or Route 53 update to redirect traffic
5. Confirm the new environment works
6. **Terminate the old environment** — RDS survives because of deletion protection
7. Delete the old CloudFormation stack (it will be in `DELETE_FAILED` state because it can't delete the protected RDS)

```
Old env ──── CNAME swap ───→ New env (no RDS)
  │                              │
  └── RDS (protected) ──────────┘
       (now independent)
```

---

## HTTPS with Beanstalk

Not covered in depth in the slides, but relevant for the exam:

- Load an SSL certificate onto the load balancer via Console or `.ebextensions`
- The certificate can be provisioned via **ACM** (AWS Certificate Manager) or uploaded as IAM server certificate
- Configure HTTPS listener on port 443 in the LB configuration
- HTTP → HTTPS redirect can be configured in the LB or via application-level redirect
- For single-instance environments (no LB), terminate SSL at the instance level using a reverse proxy (nginx) [1]

---

## Docker on Beanstalk

Beanstalk supports Docker as a platform:

**Single Container Docker** — runs one container per instance. Provide a `Dockerfile` or `Dockerrun.aws.json` (v1). Beanstalk builds and runs the image. Does not use ECS under the hood.

**Multi-Container Docker** — runs multiple containers per instance using ECS. Requires a `Dockerrun.aws.json` (v2) that defines the task definition. Beanstalk creates an ECS cluster, task definitions, and manages the containers. Images must be pre-built and stored in ECR or Docker Hub (no `Dockerfile` build support in multi-container mode) [1].

---

## References

1. [Elastic Beanstalk Developer Guide](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/)
2. [Platform Hooks](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/platforms-linux-extend.hooks.html)
3. [.ebextensions Configuration Files](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/ebextensions.html)
4. [RDS with Elastic Beanstalk](https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/AWSHowTo.RDS.html)
