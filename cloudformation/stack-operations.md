# AWS CloudFormation — Stack Operations

Topics: **rollbacks**, **service roles**, **capabilities**, **termination protection** — how stacks fail safely and how permissions are delegated.

---

## Rollbacks

### Stack Creation Failure

- **Default:** CloudFormation **rolls back** failed creates — resources created so far are generally **deleted** (subject to resource behavior and policies) [1].
- **Troubleshooting:** You can disable rollback (console/CLI) to leave failed resources for inspection — use with care [1].

### Stack Update Failure

- On update failure, CloudFormation **rolls back to the last stable stack state** [1].
- Review **Events** for the root cause (IAM, invalid property, dependency, etc.).

### `ContinueUpdateRollback`

If rollback itself gets stuck (rare but possible when resources are fixed manually), you can use **`ContinueUpdateRollback`** (console or API) to resume rollback after fixing drift/blockers [1].

---

## Service Role (CloudFormation Service Role)

A **service role** is an **IAM role** that **CloudFormation assumes** to call AWS APIs on your behalf when creating/updating/deleting stack resources [2].

### Why Use It

- **Least privilege:** Users only need `cloudformation:*` (and **`iam:PassRole`**), not every underlying service permission [2].
- **Centralized permissions:** The role holds S3, EC2, IAM, etc. permissions required by the template [2].

### `iam:PassRole`

Users (or CI) that assign the service role must be allowed to **pass** that role to the CloudFormation service [2].

```text
User permissions: cloudformation:* + iam:PassRole on the role ARN
CloudFormation assumes: service role with s3:*, ec2:*, ... as needed
```

---

## Capabilities (Acknowledgements)

Certain templates require **explicit capability flags** when you create/update stacks — otherwise CloudFormation returns **`InsufficientCapabilitiesException`** [3].

| Capability | When required |
|------------|----------------|
| `CAPABILITY_IAM` | Template creates/updates **IAM** resources without custom names (broadly) [3] |
| `CAPABILITY_NAMED_IAM` | Template creates **named** IAM resources (named roles/policies) [3] |
| `CAPABILITY_AUTO_EXPAND` | Templates use **macros**, **nested stacks**, or transforms that may expand the template [3] |

**Exam pattern:** CLI `aws cloudformation deploy ... --capabilities CAPABILITY_NAMED_IAM` when IAM resources exist [3].

---

## Termination Protection

When enabled on a stack, **DeleteStack** is blocked until protection is turned off — prevents accidental deletion [4].

- Set via console or `UpdateStack` / `CreateStack` API with termination protection flag [4].

---

## References

- [Rollback failures][1]
- [ContinueUpdateRollback API][2]
- [CloudFormation service role][3]
- [Acknowledging IAM resources in templates][4]
- [Stack termination protection][5]

[1]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-rollback-stack.html
[2]: https://docs.aws.amazon.com/AWSCloudFormation/latest/APIReference/API_ContinueUpdateRollback.html
[3]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-iam-servicerole.html
[4]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-iam-template.html
[5]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-protect-stacks.html
