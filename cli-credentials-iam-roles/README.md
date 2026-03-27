# AWS CLI, SDK, IAM Roles & Policies

This section covers the practical aspects of working with AWS programmatically, including CLI, SDKs, credentials management, and secure authentication practices. This is a critical topic for the AWS Certified Developer Associate exam.

## Files in This Section

### 1. [AWS CLI and SDK](aws-cli-sdk.md)
Covers the fundamentals of AWS CLI and SDK:
- AWS CLI overview, characteristics, and use cases
- AWS SDK overview and supported languages
- When to use CLI vs SDK vs Management Console
- Basic command structure and SDK integration

### 2. [Credentials Management](credentials-management.md)
Deep dive into AWS credentials and provider chains:
- Understanding long-term vs temporary credentials
- AWS CLI credentials provider chain (resolution order)
- AWS SDK credentials provider chain
- Best practices for managing credentials
- Credential rotation and security

### 3. [API Request Signing](signing-api-requests.md)
Understanding how AWS secures API requests:
- Signature Version 4 (SigV4) overview
- HTTP Header option (Authorization header)
- Query String option (pre-signed URLs)
- How pre-signed URLs work and security considerations
- Automatic signing by CLI and SDKs

### 4. [Service Limits and Rate Limiting](rate-limits-quotas.md)
Managing AWS API limits and handling throttling:
- API rate limits (requests per second)
- Service quotas (resource limits)
- Exponential backoff retry strategy
- When to retry vs when to request quota increase
- Monitoring and best practices

### 5. [EC2 Instance Metadata Service (IMDS)](ec2-instance-metadata.md)
Using IMDS for instance self-discovery:
- IMDS overview and available metadata
- IMDSv1 (legacy, less secure)
- IMDSv2 (modern, recommended)
- Practical IMDS usage examples
- Forcing IMDSv2 for enhanced security

### 6. [MFA with AWS CLI](mfa-with-cli.md)
Adding Multi-Factor Authentication to CLI access:
- Why MFA with CLI is important
- STS GetSessionToken API for MFA sessions
- Prerequisites and setup
- Practical scripts and SDK examples
- Enforcing MFA at policy level

---

## Key Concepts for Exam Preparation

### Credentials Provider Chain (Critical!)

**CLI Order:**
1. Command line options
2. Environment variables
3. CLI credentials file (`~/.aws/credentials`)
4. CLI configuration file (`~/.aws/config`)
5. Container credentials (ECS)
6. Instance profile credentials (EC2)

**SDK Order (Java example):**
1. Java system properties
2. Environment variables
3. Credential profiles file
4. Container credentials (ECS)
5. Instance profile credentials

### Best Practices (Exam Focus)

- **NEVER hardcode credentials** in code or config files
- **Use IAM Roles** for AWS services (EC2, ECS, Lambda)
- **Use environment variables** for CI/CD and local development
- **Implement exponential backoff** for 5xx errors and throttling
- **Use IMDSv2** instead of IMDSv1 (more secure)
- **Enable MFA** for sensitive operations and privileged users

### API Rate Limits vs Service Quotas

- **API Rate Limits**: How many requests per second (5xx → exponential backoff)
- **Service Quotas**: Total resources allowed (4xx → request increase)

### When to Use What

| Task | Tool |
|------|------|
| CI/CD pipeline | CLI in container with IAM role |
| Local development | Named profiles with `~/.aws/credentials` |
| Lambda function | Lambda execution role (automatic) |
| EC2 instance | EC2 instance profile (IMDS) |
| Application code | SDK with credentials from environment |
| Temporary access sharing | Pre-signed URL (SigV4) |
| Interactive use with MFA | `sts:GetSessionToken` + temp credentials |

---

## Practical Scenarios for Study

### Scenario 1: EC2 Instance with S3 Access

```
✓ Use EC2 instance profile with IAM role
✓ No credentials in code or environment
✓ Credentials auto-rotated from IMDS
✓ Use IMDSv2 for security
```

### Scenario 2: Lambda Function with DynamoDB

```
✓ Use Lambda execution role
✓ SDK automatically picks up credentials
✓ Credentials injected by Lambda runtime
✓ Use boto3 SDK for Python
```

### Scenario 3: Local Development with Multiple AWS Accounts

```
✓ Use named profiles in ~/.aws/credentials
✓ Set AWS_PROFILE environment variable
✓ Different access keys per profile
✓ Switch with: export AWS_PROFILE=profile-name
```

### Scenario 4: Handling API Throttling

```
✓ Implement exponential backoff
✓ Retry only on 5xx and throttling (429)
✓ Don't retry on 4xx client errors
✓ AWS SDKs handle automatically
```

### Scenario 5: Sharing S3 File Temporarily

```
✓ Use pre-signed URL (Query String SigV4)
✓ Include expiration time
✓ Share over HTTPS only
✓ Limited to single action/object
```

---

## Exam Tips

1. **Credentials Provider Chain** - Know the order for both CLI and SDKs
2. **Error Handling** - Recognize when to retry with exponential backoff vs requesting quota increase
3. **Security** - Always choose IAM roles over hardcoded credentials
4. **IMDS** - Know IMDSv2 is more secure and should be used
5. **Pre-signed URLs** - Understand SigV4 in query string format
6. **MFA with CLI** - Know sts:GetSessionToken creates temporary credentials

---

## Quick Reference

**Get CLI configured:**
```bash
aws configure
# or for specific profile
aws configure --profile myprofile
```

**Use specific profile:**
```bash
aws s3 ls --profile myprofile
# or
export AWS_PROFILE=myprofile
aws s3 ls
```

**Get temporary credentials with MFA:**
```bash
aws sts get-session-token \
  --serial-number arn:aws:iam::123456789012:mfa/user \
  --token-code 123456 \
  --duration-seconds 3600
```

**Query EC2 metadata (IMDSv2):**
```bash
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id
```

**Exponential backoff (pseudo-code):**
```
for attempt = 1 to max_attempts:
  try:
    call_api()
  catch ThrottlingException:
    delay = 2^(attempt-1) * base_delay + random_jitter
    sleep(delay)
```

---

## Related Topics

- **IAM Policies** - See the IAM section for detailed policy structure and conditions
- **EC2 Security Groups** - See EC2 section for network-level security
- **Lambda Execution Roles** - Roles for Lambda function permissions
- **CloudTrail** - Audit API calls and authentication methods
- **Security Best Practices** - Overall AWS security framework

