# Amazon S3 Security - Advanced Topics

This document covers advanced S3 security features including encryption methods, CORS, MFA Delete, access logging, pre-signed URLs, access points, and S3 Object Lambda.

## S3 Object Encryption Methods

There are four methods to encrypt S3 objects. Understanding when to use each is critical for the exam.

### SSE-S3 (Server-Side Encryption with S3-Managed Keys)

**What it is:**

- Encryption using **keys handled, managed, and owned by AWS**
- Objects encrypted server-side automatically
- **Encryption algorithm**: AES-256
- **Enabled by default** for all new S3 buckets and objects

**How to use:**

```bash
# CLI
aws s3 cp file.txt s3://my-bucket/ \
  --sse AES256

# Or set header
aws s3api put-object \
  --bucket my-bucket \
  --key file.txt \
  --body file.txt \
  --server-side-encryption AES256
```

**Pros:**

- ✓ Enabled by default (zero effort)
- ✓ No additional cost
- ✓ AWS manages key rotation
- ✓ Simple to use

**Cons:**

- ✗ Limited user control
- ✗ Can't audit which objects used which keys
- ✗ Keys not accessible for rotation by user

**Use cases:**

- Basic encryption for standard workloads
- Default choice when no special requirements

---

### SSE-KMS (Server-Side Encryption with AWS KMS)

**What it is:**

- Encryption using **AWS Key Management Service (KMS)**
- Objects encrypted server-side using KMS-managed keys
- User has **control over encryption keys** and can audit usage via CloudTrail
- Can use AWS-managed or customer-managed KMS keys

**How to use:**

```bash
# CLI with AWS-managed key
aws s3api put-object \
  --bucket my-bucket \
  --key file.txt \
  --body file.txt \
  --server-side-encryption aws:kms

# CLI with customer-managed key
aws s3api put-object \
  --bucket my-bucket \
  --key file.txt \
  --body file.txt \
  --server-side-encryption aws:kms \
  --ssekms-key-id arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012
```

**Python SDK:**

```python
import boto3

s3_client = boto3.client('s3')

# Upload with SSE-KMS
s3_client.put_object(
    Bucket='my-bucket',
    Key='file.txt',
    Body=open('file.txt', 'rb'),
    ServerSideEncryption='aws:kms',
    SSEKMSKeyId='arn:aws:kms:us-east-1:123456789012:key/12345678...'
)
```

**Advantages:**

- ✓ User control over encryption keys
- ✓ Audit key usage via CloudTrail
- ✓ Ability to rotate keys
- ✓ Cross-account encryption possible
- ✓ MFA delete protection compatible

**Disadvantages:**

- ✗ KMS API rate limits apply
- ✗ Additional cost per API call
- ✗ Slower than SSE-S3 due to KMS calls

---

### SSE-KMS Limitations

**KMS API Rate Limits:**

When using SSE-KMS, every upload and download makes KMS API calls:

- **Upload**: Calls `GenerateDataKey` KMS API
- **Download**: Calls `Decrypt` KMS API

**Rate limits per region:**

- **5,500 requests/second** (default)
- **10,000 requests/second** (if increased)
- **30,000 requests/second** (very high throughput)

**Impact:**

- If you exceed limits, S3 requests are throttled
- Error: `ThrottlingException` from KMS
- Need to request KMS quota increase via Service Quotas console

**Solution:**

```bash
# Request KMS quota increase
aws service-quotas request-service-quota-increase \
  --service-code kms \
  --quota-code L-8EFF4B5B \
  --desired-value 10000
```

---

### SSE-C (Server-Side Encryption with Customer-Provided Keys)

**What it is:**

- **You provide and manage the encryption keys** (outside AWS)
- AWS S3 does **NOT store** the encryption key
- **HTTPS is MANDATORY** for SSE-C (for security)
- Encryption key must be provided in HTTP headers for **every request**

**How to use:**

```bash
# CLI
aws s3api put-object \
  --bucket my-bucket \
  --key file.txt \
  --body file.txt \
  --sse-customer-algorithm AES256 \
  --sse-customer-key $(openssl rand -base64 32) \
  --sse-customer-key-md5 $(openssl rand -base64 32 | openssl md5 -binary | base64)
```

**Python SDK:**

```python
import boto3
import base64
import hashlib

s3_client = boto3.client('s3')

# Generate customer key
customer_key = b'your-256-bit-key-here-32-bytes!!'  # 32 bytes for AES256
customer_key_b64 = base64.b64encode(customer_key).decode('utf-8')
customer_key_md5 = base64.b64encode(
    hashlib.md5(customer_key).digest()
).decode('utf-8')

# Upload with SSE-C
s3_client.put_object(
    Bucket='my-bucket',
    Key='file.txt',
    Body=open('file.txt', 'rb'),
    SSECustomerAlgorithm='AES256',
    SSECustomerKey=customer_key_b64,
    SSECustomerKeyMD5=customer_key_md5
)
```

**Pros:**

- ✓ Complete key control and ownership
- ✓ Keys never stored by AWS
- ✓ No audit trail within AWS (intentional)
- ✓ Compliance requirements (HIPAA, PCI-DSS)

**Cons:**

- ✗ Must manage keys externally
- ✗ HTTPS only (slower than HTTP)
- ✗ Key must be provided for every request
- ✗ Complex to implement
- ✗ No CloudTrail logging of key use

**Use cases:**

- Highly sensitive data requiring external key management
- Regulatory requirements (HIPAA, PCI-DSS)
- Data sovereignty needs

---

### Client-Side Encryption

**What it is:**

- **You encrypt data before sending to S3**
- Client libraries handle encryption/decryption
- S3 stores encrypted data
- **You manage keys entirely**

**How to use:**

```python
from aws_encryption_sdk import KMSMasterKeyProvider
from aws_encryption_sdk.integrations.s3 import S3EncryptionClient
import boto3

# Set up KMS master key provider
kms_provider = KMSMasterKeyProvider(
    key_ids=['arn:aws:kms:us-east-1:123456789012:key/...']
)

# Create S3 encryption client
s3_client = boto3.client('s3')
s3_enc_client = S3EncryptionClient(
    s3_client=s3_client,
    master_key_provider=kms_provider
)

# Upload (automatic encryption)
s3_enc_client.put_object(
    Bucket='my-bucket',
    Key='file.txt',
    Body=open('file.txt', 'rb')
)
```

**Pros:**

- ✓ Complete encryption control
- ✓ S3 never sees plaintext
- ✓ Highest security level
- ✓ Full compliance flexibility

**Cons:**

- ✗ Complex implementation
- ✗ Encryption overhead on client
- ✗ Must manage key lifecycle
- ✗ Performance impact

---

### Encryption Methods Comparison


| Feature            | SSE-S3      | SSE-KMS         | SSE-C        | Client-Side  |
| ------------------ | ----------- | --------------- | ------------ | ------------ |
| **Key Management** | AWS         | AWS             | User         | User         |
| **Default**        | Yes         | No              | No           | No           |
| **CloudTrail**     | No          | Yes             | No           | No           |
| **Key Rotation**   | AWS managed | User controlled | User managed | User managed |
| **Performance**    | Fastest     | Medium          | Medium       | Slowest      |
| **Cost**           | No extra    | Per API call    | No extra     | No extra     |
| **HTTPS Required** | No          | No              | YES          | No           |
| **Exam Focus**     | High        | Very High       | Medium       | Low          |


---

## Encryption in Transit (SSL/TLS)

**Encryption in transit** (also called **in-flight encryption**) protects data while it's being transferred to/from S3.

### S3 Endpoints

S3 provides two endpoints for different security levels:

1. **HTTP Endpoint** (non-encrypted)
  - `http://my-bucket.s3.amazonaws.com`
  - Data transmitted in plaintext
  - Not recommended
2. **HTTPS Endpoint** (encrypted in transit)
  - `https://my-bucket.s3.amazonaws.com`
  - Data encrypted with TLS/SSL
  - **Recommended by AWS**
  - Default for most clients

### Forcing HTTPS-Only Access

You can use bucket policies to **deny any HTTP requests**:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*", 
      "Resource": [
        "arn:aws:s3:::my-bucket",
        "arn:aws:s3:::my-bucket/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
```

---

## Default Encryption vs. Bucket Policies

**Note:** These are two different approaches to enforce encryption.

### Default Encryption

- Automatically encrypts new objects uploaded without explicit encryption headers
- **Does NOT apply retroactively** to existing objects
- Can specify SSE-S3, SSE-KMS, or DSSE-KMS
- Applied **after** bucket policies are evaluated

### Bucket Policy Enforcement

- **Actively deny** any PUT requests without encryption headers
- More strict than default encryption
- Evaluated **before** default encryption is applied
- Can require specific encryption methods

```json
{
  "Sid": "DenyUnencryptedObjectUploads",
  "Effect": "Deny",
  "Principal": "*",
  "Action": "s3:PutObject",
  "Resource": "arn:aws:s3:::my-bucket/*",
  "Condition": {
    "StringNotEquals": {
      "s3:x-amz-server-side-encryption": ["aws:kms", "AES256"]
    }
  }
}
```

---

## Cross-Origin Resource Sharing (CORS)

### What is CORS?

**CORS (Cross-Origin Resource Sharing)** is a browser security mechanism that:

- Allows requests from one origin to access resources at a different origin
- **Origin** = protocol + domain + port

### Why CORS is Needed

Web browsers enforce the **Same-Origin Policy**:

- Scripts can only access resources from the same origin
- Protects against XSS attacks
- BUT sometimes you legitimately need cross-origin requests

**Example:** Your website loads HTML from bucket A, but wants to load images from bucket B

```
HTML from:    https://my-bucket-html.s3-website.us-west-2.amazonaws.com
Images from:  https://my-bucket-assets.s3-website.us-west-2.amazonaws.com
```

### CORS Flow

1. **Browser sends preflight request**
  ```http
   OPTIONS /
   Host: www.other.com
   Origin: https://www.example.com
  ```
2. **Server responds with CORS headers**
  ```http
   HTTP/1.1 200 OK
   Access-Control-Allow-Origin: https://www.example.com
   Access-Control-Allow-Methods: GET, PUT, DELETE
  ```
3. **Browser makes actual request** (if allowed)
  ```http
   GET /image.jpg
   Host: www.other.com
   Origin: https://www.example.com
  ```

### Configuring CORS for S3

Create a CORS configuration file:

```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "PUT", "POST"],
    "AllowedOrigins": ["https://www.example.com"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3000
  }
]
```

Apply to bucket:

```bash
aws s3api put-bucket-cors \
  --bucket my-bucket \
  --cors-configuration file://cors.json
```

### CORS Exam Example

**Popular exam scenario:** Two S3 buckets hosting static website

- Bucket A: HTML/CSS (`my-bucket-html`)
- Bucket B: Images/Assets (`my-bucket-assets`)

**Solution:** Configure CORS on Bucket B to allow requests from Bucket A

---

## MFA Delete

### What is MFA Delete?

**MFA Delete** protects against accidental or malicious deletion by requiring:

- Multi-Factor Authentication code
- Before permanently deleting object versions
- Or suspending versioning on bucket

### When MFA is Required

**Required for:**

- Permanently delete a specific **object version**
- Suspend Versioning on the bucket

**NOT required for:**

- Enable Versioning on bucket
- Create/list new versions
- List deleted versions
- Delete current version (creates delete marker, not permanent delete)

### Prerequisites

1. **Versioning enabled** on the bucket
2. **MFA device configured** for bucket owner
3. **Only bucket owner (root account)** can enable/disable MFA Delete

### Enabling MFA Delete

```bash
# Only root account can do this
aws s3api put-bucket-versioning \
  --bucket my-bucket \
  --versioning-configuration Status=Enabled,MFADelete=Enabled \
  --mfa "arn:aws:iam::123456789012:mfa/root-account-mfa-device 123456"
```

### Use Cases

- **Data protection**: Prevent accidental deletion
- **Compliance**: Meet retention requirements
- **Audit trail**: Require authorization for deletion
- **Root account security**: Ensure deliberate action

---

## S3 Access Logging

### What is S3 Access Logging?

**S3 Access Logging** records all requests made to S3 buckets:

- Every request (authorized or denied)
- Comes from any account
- Logged into a separate S3 bucket
- Useful for audit, security analysis, compliance

### How It Works

```
Requests to "monitored" bucket
    ↓
S3 logs requests
    ↓
Logs written to "logging" bucket
    ↓
Analyze logs with data analysis tools
```

### Enabling Access Logging

```bash
aws s3api put-bucket-logging \
  --bucket my-bucket \
  --bucket-logging-status '{
    "LoggingEnabled": {
      "TargetBucket": "my-logging-bucket",
      "TargetPrefix": "logs/my-bucket/"
    }
  }'
```

**Important:** Logging bucket must be in **same AWS region** as monitored bucket

### Critical Warning: Logging Loop

**DO NOT set logging bucket to be the monitored bucket!**

This creates a **logging loop** that will cause exponential bucket growth.

**Solution:** Use a separate logging bucket

---

## S3 Pre-Signed URLs

### What are Pre-Signed URLs?

**Pre-Signed URLs** are temporary URLs that grant access to S3 objects without requiring AWS credentials.

**Characteristics:**

- Inherits permissions of the user who generated it
- Temporary access (time-limited)
- Can grant different permissions (GET, PUT, etc.)
- Useful for sharing files securely

### URL Expiration

**S3 Console:**

- 1 minute to 720 minutes (12 hours)

**AWS CLI:**

- Configurable with `--expires-in` parameter
- Default: 3600 seconds (1 hour)
- Maximum: 604800 seconds (~7 days)

```bash
aws s3 presign s3://my-bucket/file.txt \
  --expires-in 3600
```

### Permissions Inheritance

**Important:** Pre-signed URL users inherit the **permissions of the URL creator** for the operation granted.

### Use Cases

1. **Premium Content Downloads**
  - Only logged-in users can download
  - Generate pre-signed URL for authenticated user
  - User clicks link and downloads directly from S3
2. **Dynamic User List**
  - Access control list changes frequently
  - Generate pre-signed URLs dynamically
3. **Temporary Upload Access**
  - Allow user to upload to specific location
  - Pre-signed PUT URL with limited permissions
  - Automatic expiration adds security

### Python Example

```python
import boto3

s3_client = boto3.client('s3')

# Generate pre-signed GET URL
url = s3_client.generate_presigned_url(
    'get_object',
    Params={'Bucket': 'my-bucket', 'Key': 'private-file.pdf'},
    ExpiresIn=3600  # 1 hour
)

# Generate pre-signed PUT URL for uploads
put_url = s3_client.generate_presigned_url(
    'put_object',
    Params={'Bucket': 'my-bucket', 'Key': 'upload-here.txt'},
    ExpiresIn=3600
)
```

---

## S3 Access Points

### What are Access Points?

**S3 Access Points** simplify security management for S3 buckets by providing:

- Independent DNS names for each access point
- Separate access point policies
- Simplified permission management at scale
- Can be Internet-facing or VPC-only

### Benefits

- **Simplify security**: Manage policies per access point instead of complex bucket policy
- **Scale**: Handle multiple applications/teams without complex conditions
- **Flexibility**: Different access patterns for different use cases

### Access Points VPC Origin

**VPC Origin** restricts access point to be accessible only from within a VPC:

**Setup requirements:**

1. Create S3 Access Point with VPC Origin
2. Create VPC Endpoint (Gateway or Interface type)
3. Configure VPC Endpoint Policy to allow access to bucket and access point
4. Only resources within VPC can access

---

## S3 Object Lambda

### What is S3 Object Lambda?

**S3 Object Lambda** allows you to use **AWS Lambda functions** to transform objects before they're returned to the requesting application.

**Key concept:** Single bucket, multiple Lambda access points, different transformations

### Use Cases

1. **Redacting PII**
  - Remove sensitive personal information
  - Different versions for analytics vs. production
  - Same source object, different outputs
2. **Format Conversion**
  - Convert XML to JSON on-the-fly
  - Support multiple formats from single storage
3. **Image Transformation**
  - Resize images based on requesting device
  - Apply watermarks based on user
  - Add overlays dynamically

### Benefits

- ✓ Single storage location
- ✓ Transform objects on-demand
- ✓ Different transforms for different applications
- ✓ Reduce storage overhead
- ✓ Real-time transformation

---

## References

- [S3 Object Encryption](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingEncryption.html)
- [SSE-KMS and KMS API Rate Limits](https://docs.aws.amazon.com/AmazonS3/latest/userguide/ServerSideEncryptionCustomerKeys.html)
- [CORS with S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/cors.html)
- [S3 Access Logging](https://docs.aws.amazon.com/AmazonS3/latest/userguide/ServerLogs.html)
- [Pre-Signed URLs](https://docs.aws.amazon.com/AmazonS3/latest/userguide/PresignedUrlUploadObject.html)
- [S3 Access Points](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-points.html)
- [S3 Object Lambda](https://docs.aws.amazon.com/AmazonS3/latest/userguide/transforming-objects-with-lambda.html)

