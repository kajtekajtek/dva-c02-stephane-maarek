# AWS CloudFormation — Overview

**AWS CloudFormation** is a service that models and provisions AWS infrastructure (and related resources) using **declarative templates**. You describe desired state; CloudFormation creates, updates, and deletes resources in a controlled order [1].

---

## What CloudFormation Does

- **Declarative IaC**: You specify *what* you want (security groups, EC2 instances, Elastic IPs, S3 buckets, load balancers, etc.), not the low-level sequencing of API calls [2].
- **Orchestration**: CloudFormation determines dependency order and applies create/update/delete operations for you [1].
- **Broad coverage**: Most AWS resource types are supported via template resources; gaps are handled with **Custom Resources** (see separate note) [1].

---

## Benefits (Exam Angle)

### Infrastructure as Code

- Fewer one-off manual changes; reproducible environments.
- Templates can live in **Git** (or any VCS): review changes like application code [2].
- **Separation of concerns**: Split work across stacks (e.g. VPC/network vs app) so teams own layers [2].

### Cost and Operations

- Stacks are tagged so you can attribute cost to a stack [2].
- You can estimate cost from the template (conceptually: same resources as if created manually) [2].
- **Dev cost savings** (slide idea): tear down non-prod stacks on a schedule and recreate — only viable when automation is reliable [2].

### Productivity

- Destroy and recreate environments quickly when templates are solid [2].
- **Infrastructure Composer** (visual editor) helps draft templates; still export/review as YAML/JSON [2].
- **Declarative** model: you avoid hand-rolling dependency ordering for standard stacks [2].

---

## How It Works (High Level)

```text
Template (YAML/JSON)
    → stored in S3 (or inline for small cases)
    → CloudFormation creates/updates a Stack
    → Stack manages AWS Resources
```

- **Template**: The desired-state document [1].
- **Stack**: A named instance of that template in an account/Region; deleting the stack deletes (by default) the resources CloudFormation created — subject to `DeletionPolicy` and stack protection [1].
- **Upload**: For larger workflows, templates are uploaded to **S3** and referenced by URL when creating/updating stacks [2].

**Update note:** You do not “edit” a template in place in S3 for history; you upload a **new object/version** and point the stack update at it [2].

---

## Deploying Templates

### Manual / Learning Path

- Edit in **Infrastructure Composer** or an IDE.
- Use the **CloudFormation console** to create/update stacks, set **parameters**, and watch events [2].

### Automated / Production Path

- Keep templates as **YAML** in repo.
- Deploy with **AWS CLI** (`create-stack`, `update-stack`, `deploy` with change sets, etc.) or **CI/CD** [2].
- Prefer automation once flows are stable [2].

---

## References

- [What is AWS CloudFormation?][1]
- [Working with CloudFormation templates][2]

[1]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html
[2]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-guide.html
