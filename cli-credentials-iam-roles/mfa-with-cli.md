# MFA with AWS CLI

This document covers how to use Multi-Factor Authentication (MFA) with the AWS Command Line Interface.

## Why MFA for CLI Access?

The AWS Management Console supports MFA for secure interactive access. However, the CLI and SDKs use access keys (long-term credentials) which are more vulnerable to compromise. **MFA with CLI** adds an additional security layer by requiring a temporary session token.

### Security Benefits

- **Defense in depth** - even if access keys are compromised, MFA is still required
- **Time-limited access** - temporary session tokens reduce exposure window
- **Compliance** - many security standards require MFA for all privileged access
- **Audit trail** - can track when temporary credentials were used

---

## How MFA with CLI Works

### The Challenge

Access keys don't directly support MFA. You can't just add `--mfa-device` to every command because:
- Access keys are static credentials
- MFA is time-based and user-interactive
- Need temporary credentials valid for the MFA session

### The Solution

Use the **AWS STS (Security Token Service)** to create a temporary session that includes MFA:

1. User provides access key + MFA token code
2. Application calls `sts:GetSessionToken` API with both credentials
3. STS returns temporary credentials (access key + secret + session token)
4. Application uses temporary credentials for subsequent API calls
5. Temporary credentials expire after configured duration

---

## Prerequisites

### Setup Requirements

1. **MFA Device Configured**
   - IAM user must have MFA device registered
   - Supported devices:
     - Virtual MFA (Google Authenticator, Authy)
     - Hardware key fob
     - U2F security key (YubiKey)

2. **User Permissions**
   - IAM user needs `sts:GetSessionToken` permission
   - User needs permission to call the actual API operations
   - Example policy:
     ```json
     {
       "Version": "2012-10-17",
       "Statement": [
         {
           "Effect": "Allow",
           "Action": "sts:GetSessionToken",
           "Resource": "*"
         },
         {
           "Effect": "Allow",
           "Action": "s3:*",
           "Resource": "*"
         }
       ]
     }
     ```

3. **Access Keys**
   - Long-term access keys for the IAM user
   - Stored in `~/.aws/credentials`

---

## Using MFA with CLI

### Step 1: Get the MFA Device ARN

First, identify your MFA device ARN. Common format:
```
arn:aws:iam::123456789012:mfa/username
```

Get it from IAM console or use CLI:

```bash
aws iam list-mfa-devices
```

Output:
```json
{
  "MFADevices": [
    {
      "UserName": "myuser",
      "SerialNumber": "arn:aws:iam::123456789012:mfa/myuser",
      "EnableDate": "2023-03-15T10:30:00Z"
    }
  ]
}
```

### Step 2: Get Temporary Credentials

Call `sts get-session-token` with your MFA device and token code:

```bash
aws sts get-session-token \
  --serial-number arn:aws:iam::123456789012:mfa/myuser \
  --token-code 123456 \
  --duration-seconds 3600
```

Parameters:
- **`--serial-number`**: ARN of your MFA device
- **`--token-code`**: 6-digit code from your MFA device (changes every 30 seconds)
- **`--duration-seconds`**: How long credentials are valid
  - Valid range: 900 seconds (15 min) to 129,600 seconds (36 hours)
  - Default: 3600 seconds (1 hour)

Response:
```json
{
  "Credentials": {
    "AccessKeyId": "ASIAJ7EXAMPLE",
    "SecretAccessKey": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
    "SessionToken": "AQoDYXdzEJr..",
    "Expiration": "2023-03-15T11:30:00Z"
  }
}
```

### Step 3: Use Temporary Credentials

Export the credentials to environment variables:

```bash
export AWS_ACCESS_KEY_ID=ASIAJ7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
export AWS_SESSION_TOKEN=AQoDYXdzEJr..

# Now use CLI with MFA session
aws s3 ls
aws ec2 describe-instances
```

---

## Practical Script: Automated MFA Session

Here's a reusable script that makes this easier:

```bash
#!/bin/bash

# Script: assume-mfa-session.sh
# Usage: ./assume-mfa-session.sh username duration
# Example: ./assume-mfa-session.sh myuser 3600

USERNAME=${1:-$USER}
DURATION=${2:-3600}
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

MFA_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:mfa/${USERNAME}"

echo "MFA Device ARN: $MFA_ARN"
echo "Session Duration: ${DURATION}s"
echo ""

# Prompt for MFA token code
read -p "Enter 6-digit MFA token code: " MFA_CODE

# Get temporary credentials
CREDENTIALS=$(aws sts get-session-token \
  --serial-number "$MFA_ARN" \
  --token-code "$MFA_CODE" \
  --duration-seconds "$DURATION" \
  --output json)

# Extract credentials
ACCESS_KEY=$(echo "$CREDENTIALS" | jq -r '.Credentials.AccessKeyId')
SECRET_KEY=$(echo "$CREDENTIALS" | jq -r '.Credentials.SecretAccessKey')
SESSION_TOKEN=$(echo "$CREDENTIALS" | jq -r '.Credentials.SessionToken')
EXPIRATION=$(echo "$CREDENTIALS" | jq -r '.Credentials.Expiration')

# Export environment variables
export AWS_ACCESS_KEY_ID="$ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$SECRET_KEY"
export AWS_SESSION_TOKEN="$SESSION_TOKEN"

echo ""
echo "✓ MFA session established"
echo "Expires: $EXPIRATION"
echo ""
echo "Use this in your current shell:"
echo "export AWS_ACCESS_KEY_ID=$ACCESS_KEY"
echo "export AWS_SECRET_ACCESS_KEY=$SECRET_KEY"
echo "export AWS_SESSION_TOKEN=$SESSION_TOKEN"
```

Save and use:
```bash
chmod +x assume-mfa-session.sh
source ./assume-mfa-session.sh myuser 3600
```

---

## Python SDK Example (boto3)

```python
import boto3
import getpass

def get_mfa_credentials(mfa_arn, duration=3600):
    """
    Get temporary credentials using MFA.
    
    Args:
        mfa_arn: ARN of MFA device (e.g., arn:aws:iam::123456789012:mfa/myuser)
        duration: Session duration in seconds (15 min to 36 hours)
    
    Returns:
        dict with temporary credentials
    """
    
    sts_client = boto3.client('sts')
    
    # Get MFA code from user
    mfa_code = input("Enter 6-digit MFA token code: ")
    
    # Get temporary credentials
    response = sts_client.get_session_token(
        SerialNumber=mfa_arn,
        TokenCode=mfa_code,
        DurationSeconds=duration
    )
    
    return response['Credentials']

# Usage
if __name__ == '__main__':
    mfa_arn = "arn:aws:iam::123456789012:mfa/myuser"
    
    creds = get_mfa_credentials(mfa_arn, duration=3600)
    
    print(f"Access Key: {creds['AccessKeyId']}")
    print(f"Expires: {creds['Expiration']}")
    
    # Create new session with temporary credentials
    session = boto3.Session(
        aws_access_key_id=creds['AccessKeyId'],
        aws_secret_access_key=creds['SecretAccessKey'],
        aws_session_token=creds['SessionToken']
    )
    
    s3_client = session.client('s3')
    buckets = s3_client.list_buckets()
```

---

## Enforcing MFA at Policy Level

You can enforce that users **must** use MFA before accessing certain resources:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": [
        "ec2:TerminateInstances",
        "rds:DeleteDBInstance",
        "s3:DeleteBucket"
      ],
      "Resource": "*",
      "Condition": {
        "BoolIfExists": {
          "aws:MultiFactorAuthPresent": "false"
        }
      }
    }
  ]
}
```

This policy denies dangerous operations unless MFA is being used (detected by presence of `SessionToken`).

---

## Common Issues and Solutions

### Issue: "User: arn:aws:iam::... is not authorized to perform: sts:GetSessionToken"

**Cause:** User doesn't have `sts:GetSessionToken` permission

**Solution:** Add to user's IAM policy:
```json
{
  "Effect": "Allow",
  "Action": "sts:GetSessionToken",
  "Resource": "*"
}
```

### Issue: "An error occurred (AccessDenied) when calling the GetSessionToken operation"

**Cause:** MFA token code invalid or expired

**Solution:** 
- Verify MFA code is correct and not expired (codes are only valid for ~30 seconds)
- Verify MFA device ARN is correct
- Check that user has MFA device properly configured

### Issue: "SECOND_MFA_REQUIRED"

**Cause:** Account has additional security requirements

**Solution:** Different MFA device might be required. Contact your AWS administrator.

---

## Best Practices

1. **Rotate Access Keys**
   - Keep long-term access keys for MFA authentication only
   - Use temporary credentials for actual work
   - Rotate long-term keys every 90 days

2. **Use Reasonable Session Duration**
   - Too short (15 min): Requires frequent re-authentication
   - Reasonable default: 1 hour
   - Long duration: More vulnerable if credentials leak

3. **Secure Your MFA Device**
   - Virtual MFA: Back up recovery codes
   - Hardware MFA: Keep in safe location
   - Authenticator app: Use account recovery options

4. **Audit MFA Usage**
   - CloudTrail logs show when `GetSessionToken` was called
   - Monitor failed MFA attempts
   - Alert on unusual patterns

5. **Combine with Other Measures**
   - Use cross-account roles for privilege separation
   - Implement least privilege policies
   - Use session duration to minimize exposure

---

## Exam Expectations

The AWS Developer exam expects you to know:
- **MFA with CLI requires** `sts:GetSessionToken` call
- **Temporary credentials** are returned from STS
- **Session token must be exported** as environment variable for subsequent CLI commands
- **Duration range**: 900 seconds to 129,600 seconds
- **Use IMDSv2** for EC2 instances (handles MFA automatically)

---

## References

- [Using MFA Devices with AWS][1]
- [GetSessionToken Documentation][2]
- [MFA Delete Protection][3]
- [Best Practices for Access Keys][4]

[1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa.html
[2]: https://docs.aws.amazon.com/STS/latest/APIReference/API_GetSessionToken.html
[3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html#MultiFactorAuthenticationDelete
[4]: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices-users-manage-accounts.html
