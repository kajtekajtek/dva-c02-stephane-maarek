# EC2 Instance Metadata Service (IMDS)

This document covers the EC2 Instance Metadata Service, how to query it, and the differences between IMDSv1 and IMDSv2.

## What is IMDS?

The **EC2 Instance Metadata Service (IMDS)** is a powerful but often underutilized feature that allows EC2 instances to:
- **Learn about themselves** - retrieve information about their own configuration
- **Discover their environment** - understand the AWS infrastructure they're running in
- **Obtain temporary credentials** - access IAM role credentials automatically

All of this is accomplished **without requiring an IAM Role**, though IAM roles are commonly used with IMDS for credential provisioning.

### Key Characteristics

- **Always available** from within EC2 instances
- **Not routable from outside the instance** (link-local address)
- **Non-authenticated** (no credentials required to query)
- **Link-local HTTP endpoint** at `169.254.169.254`
- **IPv6 equivalent** at `fd00:ec2::254/128`

---

## IMDS vs Userdata

Both allow EC2 instances to access launch-time information, but they serve different purposes:

| Aspect | Metadata (IMDS) | Userdata |
|--------|-----------------|----------|
| **What** | Info *about* the instance | Script *to run* at launch |
| **Accessed** | During instance lifetime | Only at launch |
| **Type** | Instance configuration data | Shell script or commands |
| **Example Data** | Instance ID, IAM role | Commands to install software |
| **Retrievable** | Via HTTP API | Not directly retrievable |
| **Use Cases** | Auto-discovery, self-configuration | One-time setup tasks |

---

## IMDS Information Available

Common metadata you can retrieve:

### Instance Identity Information

```
/latest/meta-data/instance-id
/latest/meta-data/instance-type
/latest/meta-data/ami-id
/latest/meta-data/ami-launch-index
/latest/meta-data/hostname
/latest/meta-data/local-hostname
/latest/meta-data/local-ipv4
/latest/meta-data/public-hostname
/latest/meta-data/public-ipv4
```

### Network Information

```
/latest/meta-data/network/interfaces/macs
/latest/meta-data/network/interfaces/macs/{mac}/security-groups
/latest/meta-data/network/interfaces/macs/{mac}/subnet-id
/latest/meta-data/network/interfaces/macs/{mac}/vpc-id
```

### IAM Role Information

```
/latest/meta-data/iam/security-credentials
/latest/meta-data/iam/security-credentials/{role-name}
```

### Placement Information

```
/latest/meta-data/placement/availability-zone
/latest/meta-data/placement/region
/latest/meta-data/placement/group-name
```

### Complete Metadata Tree

```bash
http://169.254.169.254/latest/meta-data/
```

### Important Limitation

**You CAN retrieve:** IAM Role name from metadata

```bash
curl http://169.254.169.254/latest/meta-data/iam/security-credentials
# Returns: role-name
```

**You CANNOT retrieve:** IAM Role policies from metadata

There is no direct API to read the policies attached to a role from IMDS. Policies must be queried via the IAM API with appropriate permissions.

---

## IMDSv1 (Legacy)

IMDSv1 is the original IMDS implementation. It's simpler but less secure.

### How It Works

Simple HTTP GET request directly to the metadata endpoint:

```bash
curl http://169.254.169.254/latest/meta-data/

# Retrieve specific metadata
curl http://169.254.169.254/latest/meta-data/instance-id

# Retrieve IAM role credentials
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/my-role-name
```

### Security Issues

1. **Vulnerable to SSRF attacks**
   - Application with SSRF vulnerability can access IMDS
   - Attacker can retrieve instance credentials

2. **Exposed to container escape**
   - Container escape could expose host IMDS

3. **No token/session verification**
   - Any request is valid

### Example Attack Scenario

```
1. Application accepts user-provided URL parameter
2. Application makes HTTP request to user-provided URL
3. Attacker provides URL: http://169.254.169.254/latest/meta-data/iam/security-credentials/role-name
4. Application makes request and gets IAM credentials back
5. Attacker can now use stolen credentials
```

### Deprecation Status

- **Still supported** by AWS (for backward compatibility)
- **No longer recommended** by AWS
- **Should be disabled** in security-conscious organizations

---

## IMDSv2 (Recommended)

IMDSv2 is the modern, more secure version of IMDS. It uses a **session-oriented** approach.

### Key Improvements

1. **Prevents SSRF attacks** - requires a token obtained separately
2. **Session-based** - temporary token with TTL
3. **Requires explicit opt-in** - metadata not accessible without token
4. **Works with containerized apps** - compatible with container security

### How It Works

IMDSv2 requires a **two-step process**:

#### Step 1: Get a Session Token

Make a PUT request with specific headers:

```bash
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
```

Parameters:
- **Method**: `PUT` (not GET)
- **Endpoint**: `/latest/api/token`
- **Header**: `X-aws-ec2-metadata-token-ttl-seconds: {seconds}`
  - TTL value: 1 second to 21600 seconds (6 hours)
  - Choose based on expected session duration

Response:
- **Token string** (example): `AQAAAHxJx8Vf_example_token==`

#### Step 2: Use Token in Metadata Requests

Include the token in all subsequent metadata requests:

```bash
# Using the token from step 1
curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id

# Retrieve IAM credentials with token
curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/iam/security-credentials/my-role-name
```

Parameters:
- **Header**: `X-aws-ec2-metadata-token: {token_value}`
- Token remains valid until TTL expires or instance terminates

### Complete IMDSv2 Example

```bash
#!/bin/bash

# Step 1: Get token
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

# Step 2: Use token for metadata queries
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)

INSTANCE_TYPE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-type)

AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/availability-zone)

echo "Instance ID: $INSTANCE_ID"
echo "Instance Type: $INSTANCE_TYPE"
echo "Availability Zone: $AZ"
```

### IMDSv2 with AWS SDK

Modern AWS SDKs handle IMDSv2 automatically:

**Python (boto3):**
```python
import boto3

# boto3 automatically uses IMDSv2 when available
ec2 = boto3.client('ec2')
```

**Node.js:**
```javascript
const AWS = require('aws-sdk');
// AWS SDK automatically uses IMDSv2
```

---

## Forcing IMDSv2 (Best Practice)

### Disable IMDSv1

You can configure EC2 instances to **only accept IMDSv2** requests:

**Via Console:**
1. Launch instance
2. In advanced details → Metadata options
3. Set "Metadata Version" to "V2 only"

**Via CLI:**
```bash
aws ec2 run-instances \
  --image-id ami-12345678 \
  --instance-type t3.micro \
  --metadata-options "HttpTokens=required,HttpPutResponseHopLimit=1"
```

**Via Terraform:**
```hcl
resource "aws_instance" "example" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # Enforce IMDSv2
    http_put_response_hop_limit = 1
  }
}
```

### Security Benefits

- **Prevents SSRF attacks** - no way to access metadata without token
- **Complies with security standards** - AWS security best practices
- **Container-safe** - compatible with containerized workloads
- **Zero downside** - modern applications handle it automatically

---

## Real-World Usage Examples

### Auto-Discovery Application Configuration

```bash
#!/bin/bash

# Get metadata to discover instance environment
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 300")

AVAILABILITY_ZONE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/availability-zone)

REGION=${AVAILABILITY_ZONE%?}  # Remove last character (AZ letter)

# Use discovered region to configure application
export AWS_REGION=$REGION
```

### Retrieve IAM Role Credentials

```python
import boto3
import requests
import json

def get_credentials_from_imds(role_name):
    # Get IMDSv2 token
    token = requests.put(
        'http://169.254.169.254/latest/api/token',
        headers={'X-aws-ec2-metadata-token-ttl-seconds': '21600'}
    ).text
    
    # Use token to get credentials
    url = f'http://169.254.169.254/latest/meta-data/iam/security-credentials/{role_name}'
    response = requests.get(
        url,
        headers={'X-aws-ec2-metadata-token': token}
    )
    
    credentials = response.json()
    return credentials

# Normally handled automatically by boto3, but shows how IMDS works
creds = get_credentials_from_imds('my-instance-role')
print(creds)
```

---

## Exam Expectations

The AWS Developer exam expects you to know:
- **IMDS exists** and what it does
- **IMDSv1 vs IMDSv2** differences and security implications
- **Can retrieve IAM role name** from IMDS
- **Cannot retrieve IAM policies** from IMDS
- **Use IMDSv2** for production (more secure)
- **Link-local address**: `169.254.169.254`
- **Token-based approach** of IMDSv2

---

## References

- [Instance Metadata Service Documentation][1]
- [IMDSv2 Technical Details][2]
- [EC2 Instance Metadata Query Tool][3]
- [Security Considerations for IMDS][4]

[1]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html
[2]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html
[3]: https://aws.amazon.com/blogs/compute/exploring-ec2-instance-metadata/
[4]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html#instance-metadata-security
