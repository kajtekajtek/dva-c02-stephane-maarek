# AWS CloudFormation — Custom Resources

Use **custom resources** when you need logic or APIs **not covered** by native CloudFormation resource types, or when you must run **custom code** during create/update/delete [1].

---

## Why Custom Resources Exist

- Integrate **third-party** APIs or **on-premises** systems [1].
- Perform **side effects** during lifecycle (e.g. empty an S3 bucket before delete) [1].
- Bridge gaps until a native resource type exists [1].

---

## Declaration Styles

- **`AWS::CloudFormation::CustomResource`** — generic custom resource [1].
- **`Custom::MyLogicalId`** — namespaced custom type string (common with Lambda providers) [1].

---

## Provider: Lambda or SNS

- **`ServiceToken`** (required): ARN of **Lambda** or **SNS** that receives CloudFormation custom resource requests [1].
- **Same Region** as the stack for the provider (typical constraint for Lambda-backed) [1].

CloudFormation sends **Create**, **Update**, and **Delete** requests to the provider; the provider must respond with success/failure and optional data [1].

---

## Classic Pattern: Empty S3 Bucket Before Delete

Problem: **Cannot delete a non-empty bucket**; stack delete fails [1].

Solution: **Custom resource (Lambda)** on delete that **lists and deletes objects** (and optionally versions) **before** CloudFormation deletes the bucket [1].

---

## Security and Operations

- Lambda needs IAM permissions for **S3 list/delete**, **CloudWatch Logs**, and **callback to CloudFormation** (via `cfn-response` or SDK) [1].
- **Timeouts**: Custom resources must complete within service limits — long work should be async patterns [1].

---

## References

- [Custom resources][1]
- [Custom resource reference][2]

[1]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-custom-resources.html
[2]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-cfn-customresource.html
