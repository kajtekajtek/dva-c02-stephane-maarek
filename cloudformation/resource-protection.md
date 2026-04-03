# AWS CloudFormation — Resource Protection

**DeletionPolicy**, **Stack policies**, and related controls decide what survives stack deletes and what can change during updates [1][2].

---

## DeletionPolicy

Set on individual **resources** to control behavior when the resource is **removed from the template** or the **stack is deleted** [1].

| Policy | Behavior |
|--------|----------|
| **Delete** (default) | CloudFormation deletes the resource (service rules still apply — e.g. non-empty S3 bucket) [1] |
| **Retain** | Resource is **orphaned** in the account — stack delete does not delete it [1] |
| **Snapshot** | For supported resources, create a **snapshot** before delete (EBS, RDS, etc.) [1] |

### S3 Bucket Caveat (Exam Favorite)

- Default **Delete** may **fail** if the bucket **is not empty** — empty objects/versioning/delete markers may block deletion [1].

---

## Stack Policy

A **stack policy** is a JSON document attached to a stack that **restricts update operations** on resources during **stack updates** [2].

### Semantics (Course Version)

- After you attach a stack policy, **updates that are not explicitly allowed can be denied** — the course slide emphasizes **protecting production** resources from accidental changes [2].
- Design pattern: **deny by default** for sensitive resources, then **ALLOW** only what you intend to change [2].

**Note:** Stack policies affect **stack updates**, not arbitrary console edits outside CloudFormation (but drift is still a separate topic).

---

## Relationship to Other Controls

- **Termination protection**: blocks **stack delete** entirely (see `stack-operations.md`) [3].
- **DeletionPolicy**: stack-level delete vs retain at **resource** level [1].
- **Stack policy**: **which resource updates** are permitted during `UpdateStack` [2].

---

## References

- [DeletionPolicy attribute][1]
- [Prevent updates to stack resources][2]
- [Stack termination protection][3]

[1]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html
[2]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/protect-stack-resources.html
[3]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-protect-stacks.html
