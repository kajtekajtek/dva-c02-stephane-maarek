# Amazon S3 Security

## S3 Security

### User-Based

- **Identity-based policies**
  - JSON permission documents attached to an **IAM identity**
  - Identities: user, group, or role
  - Control which **actions** an identity can perform on which **resources** and under which **conditions**
  - **Inline** (one identity) or **managed** (reusable, attach to multiple identities)
  - By default, identities have **no** permissions until an administrator attaches policies
- **Managing access using policies**
  - Administrators define **who** can do **what** on **which** resources
  - Policies stored in AWS as JSON (most cases) [1]

### Resource-Based

- **Resource-based policies**
  - JSON policy documents attached to a **resource**
  - For S3: **bucket policy** (and similar patterns in other services)
  - **Principal** must be specified in a resource-based policy
  - **Inline** to that resource in the service
  - Cannot embed **AWS managed policies** from IAM inside a resource-based policy
- **Examples**
  - S3 bucket policy
  - IAM role **trust** policy (cross-service pattern) [1]

### Object access by IAM principal

**Note**: an IAM principal can access an S3 object if
- The user IAM permissions ALLOW it OR the resource policy ALLOWS it
- AND there’s no explicit DENY

### Encryption

- **Scope**
  - **In transit**: data moving to and from S3
  - **At rest**: data on disks in AWS data centers
- **In transit**
  - SSL/TLS
  - Hybrid post-quantum key exchange (optional path)
  - Client-side encryption (you manage keys and ciphertext before upload)
- **At rest (server-side)**
  - S3 encrypts before persist, decrypts on read
  - **SSE-S3**: default for every bucket; **automatic** encryption for new uploads (announced Jan 2023) at no extra cost for that default behavior
  - Per-`PUT` or default bucket encryption can use **SSE-KMS**, **DSSE-KMS**, or **SSE-C** where supported
  - Changing bucket default encryption does **not** re-encrypt existing objects; use **S3 Batch Operations** copy to migrate ciphertext type when needed
- **At rest (client-side)**
  - You encrypt before upload; you manage keys and tooling [5]

## S3 Bucket Policies

### JSON based policies



- **Resource**: The Amazon S3 bucket, object, access point, or job that the policy applies to. 
    - Use the Amazon Resource Name (ARN) to identify the resource.
- **Actions**: identify resource operations that you will allow (or deny) by using action keywords.
- **Effect**: What the effect will be when the user requests the specific action—this can be either Allow or Deny.
    - If you don't explicitly grant access to (allow) a resource, access is implicitly denied. 
- **Principal**: User, account, service, or other entity that is the recipient of this permission.
- **Condition**: Conditions for when a policy is in effect. 

```json
{
    "Version":"2012-10-17",		 	 	 
    "Id": "ExamplePolicy01",
    "Statement": [
        {
            "Sid": "ExampleStatement01",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::123456789012:user/Akua"
            },
            "Action": [
                "s3:GetObject",
                "s3:GetBucketLocation",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::amzn-s3-demo-bucket1/*",
                "arn:aws:s3:::amzn-s3-demo-bucket1"
            ]
        }
    ]
}
```

### Bucket Policies Use Cases

- Grant public access to the bucket
- Force objects to be encrypted at upload
- **Cross-account**
  - Grant another account permission to upload to your bucket
  - Pair with patterns so **you** retain full control of uploaded objects (see doc examples)
- **Condition keys**
  - Restrict by IP, VPC endpoint, encryption headers, etc. (dedicated condition-key topics in docs)
- **VPC**
  - Restrict access to traffic from specific **VPC endpoints** (dedicated examples in docs)
- **Further examples**
  - See **Examples of Amazon S3 bucket policies** in AWS docs [4]

## Examples

### Public Access

- **Granting public access**
  - ACLs
  - Bucket policies
  - Access point policies
  - Any of these can expose data if misconfigured
- **Block Public Access**
  - Settings at **organization**, **account**, **bucket**, **access point**
  - **Override** public grants so you can enforce centralized limits
  - **Four** independent settings; **most restrictive** combination across levels wins
  - **Org** level: all four on or off together (no per-setting granularity)
- **Default**
  - New buckets and access points **do not** allow public access until you change policies or ACLs
  - Still recommended to enable **Block Public Access** broadly [6]

### User Access to S3

- Create **IAM users**, **groups**, **roles** in the account
- Attach **identity-based policies** granting `s3:*` actions on bucket and object ARNs as needed
- Prefer **roles** and temporary credentials over long-lived users where possible
- **Root user**: avoid for routine operations; use admin role pattern instead [1]

### EC2 Instance Access

- Assign an **IAM role** to the instance (or workload)
- Application uses **temporary** credentials from the role to call S3 APIs
- Same role pattern supports **cross-service** and **cross-account** access when trust and policies allow [1]

### Cross-Account Access

- **Bucket policy**
  - `Principal` can identify another account or its IAM principals (per policy syntax rules)
  - Common pattern for delegating upload or read to a trusted account
- **Permission delegation**
  - Owning account grants permissions to account B; B can delegate to **its own** users/roles, but not forward cross-account again from B to C in the same way
- **Object ownership**
  - If another account uploads and owns objects, bucket owner may still **deny** or **delete** per bucket-owner powers; Object Ownership settings change default ownership model [2][4]

### Bucket Settings for Block Public Access

- **Purpose**
  - Block public reads/writes even if ACL or policy would allow `public` principals
- **Levels**
  - Organization, account, bucket, access point (evaluation combines to **strictest**)
- **Not per-object**
  - Block Public Access is **not** defined per object; scope is org/account/bucket/access point
- **Account scope**
  - Account-level settings apply **globally** across Regions (eventual consistency across Regions)
- **Four settings (summary)**
  - Block new public ACLs and block public ACLs on existing objects
  - Block public bucket policies that grant public access
  - (See doc table for exact API behaviors per setting)
- **Recommendation**
  - Enable all four at account and bucket where possible; validate apps that truly need public read via CloudFront or presigned URLs instead of open buckets [6]

## References

- [Identity and Access Management for Amazon S3 at docs.aws.amazon.com][1]
- [Access control in Amazon S3 at docs.aws.amazon.com][2]
- [How Amazon S3 authorizes a request at docs.aws.amazon.com][3]
- [Bucket policies for Amazon S3 at docs.aws.amazon.com][4]
- [Protecting data with encryption at docs.aws.amazon.com][5]
- [Blocking public access to your Amazon S3 storage at docs.aws.amazon.com][6]

[1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-iam.html
[2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-management.html
[3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/how-s3-evaluates-access-control.html
[4]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucket-policies.html
[5]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingEncryption.html
[6]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html
