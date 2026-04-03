# AWS CloudFormation — StackSets

**StackSets** extend CloudFormation to create/update/delete **stack instances** across **multiple accounts and Regions** from a single template and operation [1].

---

## What Problem It Solves

- **Organization-wide** baselines (logging, guardrails, networking).
- **Multi-account** deployments without repeating the same stack create in every account [1].

---

## Core Concepts

| Concept | Meaning |
|---------|---------|
| **StackSet** | Container for a template + targets + deployment options [1] |
| **Stack instance** | A stack in one **account + Region** pair managed by the set [1] |
| **Administrator account** | Where you **create/manage** the StackSet (management account or delegated admin) [1] |
| **Target accounts** | Accounts that receive stack instances [1] |

---

## Behavior

- **Single operation** can deploy or update **many** stack instances [1].
- When you **update** a StackSet, associated **stack instances** are updated per your concurrency/failure settings [1].
- Tight **AWS Organizations** integration: target OUs or accounts [1].

### Permissions (High Level)

- Typically **organization management account** or **delegated StackSets administrator** [1].
- Target accounts need **trust** for StackSets service roles — follow the StackSets setup guide for your org [1].

---

## vs Single Stack

- **Stack**: one account, one Region (unless you manually repeat).
- **StackSet**: **many** accounts/Regions, **one** definition, **controlled rollout** [1].

---

## References

- [Working with StackSets][1]
- [StackSets concepts][2]

[1]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/what-is-cfnstacksets.html
[2]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stacksets-concepts.html
