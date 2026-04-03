# AWS CloudFormation — Resources

The **`Resources`** section is **mandatory** in a template: it declares AWS (and AWS::CloudFormation) objects CloudFormation will create, update, or delete [1].

---

## Resource Type Identifiers

Each resource has a `Type` in the form:

```text
service-provider::service-name::data-type-name
```

Examples:

- `AWS::EC2::Instance`
- `AWS::EC2::SecurityGroup`
- `AWS::S3::Bucket`

There are **hundreds** of resource types; the exact set grows over time [2].

---

## Logical ID vs Physical ID

- **Logical ID** (your key under `Resources:`): stable within the template; used with `Ref` / `Fn::GetAtt`.
- **Physical ID**: the real AWS identifier after creation (e.g. `i-0abc…`, `sg-0abc…`). `Ref` on a resource often returns the physical ID depending on type [1].

---

## How to Learn a Resource Type

1. Open the **resource type reference** for the service [2].
2. Open the page for the specific type (e.g. `AWS::EC2::Instance`) [3].
3. Copy **required** `Properties`, note **defaults**, and check **return values** (`Ref`, `Fn::GetAtt` attributes).

You cannot memorize every property; the skill is **reading the docs** and composing valid templates [2].

---

## FAQ (From Slides + Docs)

### Dynamic Number of Resources?

- **Not** with plain `Resources:` alone — you declare fixed logical IDs.
- For repetition/generation, use patterns such as **nested stacks**, **macros**, **Transforms**, or generate templates outside CloudFormation [4].

### Is Every AWS Service Supported?

- **Almost** — most services have native types; edge cases may lag or need **Custom Resources** [4].

### Unsupported or Custom Behavior?

- Use **`AWS::CloudFormation::CustomResource`** or a **`Custom::YourType`** backed by Lambda/SNS (see `custom-resources.md`) [4].

---

## References

- [Resources section][1]
- [Resource and property reference][2]
- [AWS::EC2::Instance][3]
- [Custom resources][4]

[1]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resources-section-structure.html
[2]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html
[3]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-instance.html
[4]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-custom-resources.html
