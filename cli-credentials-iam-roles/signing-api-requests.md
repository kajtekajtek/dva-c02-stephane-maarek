# AWS API Request Signing

This document covers how AWS secures API requests through cryptographic signing using Signature Version 4 (SigV4).

## Why Request Signing Matters

When you call an AWS API, AWS needs to:
1. **Verify your identity** - confirm you are who you claim to be
2. **Ensure authenticity** - verify the request came from you, not someone else
3. **Detect tampering** - ensure the request wasn't modified in transit
4. **Prevent replay attacks** - prevent old requests from being replayed

This is accomplished through **cryptographic signing** of your API requests.

---

## Signature Version 4 (SigV4)

**SigV4** is the current standard for signing AWS API requests. It's more secure than the deprecated SigV2.

### How SigV4 Works

1. **Create a canonical request** - standardized representation of the request
2. **Create a string to sign** - includes credential scope and canonical request hash
3. **Calculate the signature** - HMAC-SHA256 hash using your secret access key
4. **Add signature to request** - include signature in request headers or query string

### Key Components of a Signature

- **Access Key ID** - identifies which credentials were used
- **Credential Scope** - scope of validity (date/region/service)
- **Hashed Payload** - cryptographic hash of request body
- **Timestamp** - includes date and time (prevents replay attacks)
- **Signed Headers** - list of headers included in signature
- **HMAC-SHA256 Signature** - computed hash

---

## HTTP Header Option

The most common approach for signing requests. The signature is included in the **Authorization header**.

### Authorization Header Format

```
Authorization: AWS4-HMAC-SHA256 
Credential=AccessKeyId/YYYYMMDD/region/service/aws4_request,
SignedHeaders=header1;header2;header3,
Signature=SignatureValue
```

### Example Request with SigV4 Header

```http
GET /my-file.txt HTTP/1.1
Host: s3.amazonaws.com
X-Amz-Date: 20230315T123456Z
Authorization: AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/20230315/us-east-1/s3/aws4_request, SignedHeaders=host;x-amz-date, Signature=abc123def456...
```

### Components Explained

**Credential Scope:**
```
AccessKeyId/YYYYMMDD/region/service/aws4_request
AKIAIOSFODNN7EXAMPLE/20230315/us-east-1/s3/aws4_request
```
- Scopes the credentials to specific date, region, and service
- Limits damage if credentials are compromised

**SignedHeaders:**
```
host;x-amz-date;x-amz-content-sha256
```
- List of HTTP headers included in the signature
- At minimum: `Host` and `X-Amz-Date`
- Any other headers you want to integrity-protect

**Signature:**
```
abc123def456...
```
- HMAC-SHA256 hash computed from:
  - String to sign
  - Secret access key
  - Credential scope

### When to Use Header Option

- Standard use case for SDK and CLI
- HTTPS requests with Authorization header
- Request body can be large
- Standard HTTP clients and proxies handle it well

---

## Query String Option

The signature is included as query string parameters instead of an Authorization header. Commonly used for **S3 Pre-Signed URLs**.

### Query String Format

```
https://s3.amazonaws.com/bucket/key?
  X-Amz-Algorithm=AWS4-HMAC-SHA256&
  X-Amz-Credential=AccessKeyId/20230315/us-east-1/s3/aws4_request&
  X-Amz-Date=20230315T123456Z&
  X-Amz-Expires=3600&
  X-Amz-SignedHeaders=host&
  X-Amz-Signature=abc123def456...
```

### Key Parameters

- **X-Amz-Algorithm**: Signing algorithm (`AWS4-HMAC-SHA256`)
- **X-Amz-Credential**: Access key and credential scope
- **X-Amz-Date**: Request timestamp in ISO8601 format
- **X-Amz-Expires**: How long the URL is valid (in seconds)
- **X-Amz-SignedHeaders**: Headers included in signature
- **X-Amz-Signature**: The computed signature

### Example: S3 Pre-Signed URL

```python
import boto3
from datetime import datetime

s3_client = boto3.client('s3')

# Generate pre-signed URL valid for 1 hour
url = s3_client.generate_presigned_url(
    'get_object',
    Params={'Bucket': 'my-bucket', 'Key': 'my-file.txt'},
    ExpiresIn=3600
)

print(url)
# Output:
# https://my-bucket.s3.amazonaws.com/my-file.txt?
#   X-Amz-Algorithm=AWS4-HMAC-SHA256&
#   X-Amz-Credential=AKIA.../20230315/.../aws4_request&
#   X-Amz-Date=20230315T123456Z&
#   X-Amz-Expires=3600&
#   X-Amz-SignedHeaders=host&
#   X-Amz-Signature=...
```

### When to Use Query String Option

- **Pre-signed URLs** for temporary file access
- Sharing download/upload links with users
- HTML forms that submit to S3 directly
- URLs that need to be valid for a specific duration
- Scenarios where Authorization headers aren't available

### Important Security Considerations

- URLs are valid for the specified time only (`X-Amz-Expires`)
- Anyone with the URL can perform the action (GET, PUT, etc.)
- Should be shared over HTTPS only
- Keep expiration time minimal
- Can be revoked by changing S3 bucket policies or IAM permissions

---

## Automatic Signing by CLI and SDKs

When you use the AWS CLI or SDKs, request signing is **handled automatically**:

```bash
# CLI automatically signs requests
aws s3 cp myfile.txt s3://mybucket/

# SDK automatically signs requests
s3_client = boto3.client('s3')
s3_client.put_object(Bucket='mybucket', Key='myfile.txt', Body=b'content')
```

You don't need to manually compute signatures - the SDK/CLI handles:
- Canonical request creation
- Timestamp generation
- Payload hashing
- Signature computation
- Header insertion

### Why This Matters for the Exam

- Understand **why** requests are signed (security, identity verification)
- Know **when** SigV4 is used (always, for API requests)
- Recognize **header vs. query string** options and their use cases
- Understand **pre-signed URLs** and their security implications
- Know that **SDK/CLI handle signing automatically**

---

## Security Best Practices

1. **Always use HTTPS**
   - Encrypts the request in transit
   - Prevents credential interception
   - Required for production use

2. **Keep Credentials Secure**
   - Never hardcode in code
   - Rotate access keys regularly
   - Use IAM roles when possible

3. **Use Pre-Signed URLs Carefully**
   - Set appropriate expiration times
   - Limit the scope (specific object/action)
   - Only share over secure channels (HTTPS, encrypted email, etc.)
   - Revoke by changing permissions if needed

4. **Monitor Request Signing**
   - Use CloudTrail to log API calls
   - Check CloudTrail for unauthorized access attempts
   - Monitor access key usage

---

## References

- [Authenticating Requests with SigV4][1]
- [AWS Signature Version 4 Signing Process][2]
- [Presigned URLs][3]
- [SigV4 Examples][4]

[1]: https://docs.aws.amazon.com/general/latest/gr/signing_aws_api_requests.html
[2]: https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html
[3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/PresignedUrlUploadObject.html
[4]: https://docs.aws.amazon.com/general/latest/gr/sigv4-signed-request-examples.html
