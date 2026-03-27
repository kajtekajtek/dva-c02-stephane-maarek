# AWS Credentials Management

This document covers how AWS credentials are managed, provided, and secured when using the AWS CLI, SDKs, and applications.

## Understanding AWS Credentials

### Types of Credentials

AWS provides two primary ways to authenticate:

1. **Long-term Credentials** (IAM User Access Keys)
   - Access Key ID (username-like identifier)
   - Secret Access Key (password-like secret)
   - Never expire automatically
   - Should be rotated regularly for security

2. **Temporary Credentials** (STS Session Token)
   - Access Key ID
   - Secret Access Key
   - Session Token
   - Limited validity period
   - Auto-expire after specified duration
   - More secure than long-term credentials

### Access Key Structure

**Access Key ID:**
- Public identifier
- Format: `AKIAIOSFODNN7EXAMPLE`
- Used in authorization headers
- Can be exposed in logs

**Secret Access Key:**
- Private secret (like a password)
- Format: 40-character string
- Should never be committed to version control
- Must be stored securely

---

## AWS CLI Credentials Provider Chain

The AWS CLI searches for credentials in a **specific order** and uses the first valid set it finds. This is the **credentials provider chain**.

### CLI Credentials Resolution Order

1. **Command Line Options**
   - Highest priority
   - Examples: `--region`, `--output`, `--profile`
   - Syntax: `aws s3 ls --region us-west-2 --profile myprofile`

2. **Environment Variables**
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_SESSION_TOKEN` (for temporary credentials)
   - Example:
     ```bash
     export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
     export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
     aws s3 ls
     ```

3. **CLI Credentials File** (`~/.aws/credentials`)
   - Location: `~/.aws/credentials` on Linux/Mac
   - Location: `C:\Users\USERNAME\.aws\credentials` on Windows
   - Format: INI file with named profiles
   - Example:
     ```ini
     [default]
     aws_access_key_id=AKIAIOSFODNN7EXAMPLE
     aws_secret_access_key=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

     [myprofile]
     aws_access_key_id=AKIAIOSFODNN7EXAMPLE2
     aws_secret_access_key=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY2
     ```

4. **CLI Configuration File** (`~/.aws/config`)
   - Location: `~/.aws/config` on Linux/macOS
   - Location: `C:\Users\USERNAME\.aws\config` on Windows
   - Stores region and output format preferences
   - Example:
     ```ini
     [default]
     region=us-east-1
     output=json

     [profile myprofile]
     region=us-west-2
     output=table
     ```

5. **Container Credentials** (ECS Tasks)
   - For applications running in ECS containers
   - Credentials provided by ECS Agent
   - Automatic temporary credential rotation
   - Retrieved from environment variable: `AWS_CONTAINER_CREDENTIALS_RELATIVE_URI`

6. **Instance Profile Credentials** (EC2 Instances)
   - Lowest priority
   - Credentials attached via IAM Instance Profile
   - Retrieved from EC2 Instance Metadata Service (IMDS)
   - Automatic refresh of temporary credentials

### Setting Up CLI Credentials

Use the `aws configure` command for initial setup:

```bash
$ aws configure
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: us-east-1
Default output format [None]: json
```

This creates/updates both `~/.aws/credentials` and `~/.aws/config` files.

### Multiple Profiles

Use named profiles for managing multiple AWS accounts or IAM users:

```bash
# Configure additional profile
aws configure --profile myprofile

# Use specific profile
aws s3 ls --profile myprofile

# Set default profile via environment
export AWS_PROFILE=myprofile
aws s3 ls  # Uses myprofile credentials
```

---

## AWS SDK Default Credentials Provider Chain

SDKs have their own credentials provider chain, similar to CLI but with language-specific variations.

### Java SDK Credentials Resolution Order

1. **Java System Properties**
   - `aws.accessKeyId`
   - `aws.secretKey`
   - Set via: `java -Daws.accessKeyId=XXX -Daws.secretKey=YYY MyApp.jar`

2. **Environment Variables**
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_SESSION_TOKEN`

3. **Default Credential Profiles File**
   - Location: `~/.aws/credentials` (shared with CLI)
   - Shared by many SDKs

4. **Amazon ECS Container Credentials**
   - For ECS container applications
   - Automatic credential rotation
   - Retrieved from ECS Agent

5. **Instance Profile Credentials**
   - Used on EC2 instances
   - Retrieved from EC2 Instance Metadata Service
   - Automatic refresh

### Python SDK (boto3) Credentials Resolution

```python
import boto3

# Credentials resolved automatically in this order:
# 1. Environment variables
# 2. ~/.aws/credentials
# 3. ~/.aws/config
# 4. EC2 Instance Profile / ECS Task Credentials

# Explicitly specify credentials (not recommended in production)
client = boto3.client(
    's3',
    aws_access_key_id='AKIAIOSFODNN7EXAMPLE',
    aws_secret_access_key='wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
)

# Use specific profile
session = boto3.Session(profile_name='myprofile')
client = session.client('s3')
```

### Credential Provider Chain Implications

The credential chain can cause **unexpected access** if credentials are available from multiple sources. 

**Example Scenario:**
- An application uses environment variables with IAM user credentials (S3FullAccess)
- An IAM Role with restricted S3 bucket access is attached to the EC2 instance
- The application still has access to all S3 buckets because environment variables take priority in the chain
- **Solution**: Remove environment variables; let the SDK use the EC2 Instance Profile

---

## AWS Credentials Best Practices

### Golden Rules

1. **NEVER store credentials in code**
   - Don't commit to version control
   - Don't hardcode in application source
   - Don't include in configuration files bundled with code

2. **Use the Credentials Provider Chain**
   - Let the SDK/CLI discover credentials automatically
   - Follow the priority order to avoid conflicts
   - Leverage built-in caching and refresh mechanisms

3. **Service-Specific Approaches**

   **For EC2 Instances:**
   - Use IAM Instance Profile (Instance Role)
   - Credentials retrieved automatically from IMDS
   - Temporary credentials rotated automatically
   ```bash
   # No manual credential configuration needed
   aws s3 ls  # Uses instance role credentials
   ```

   **For ECS Tasks:**
   - Use ECS Task Role
   - Credentials provided via ECS Agent
   - Automatic rotation per task

   **For Lambda Functions:**
   - Use Lambda Execution Role
   - Credentials automatically injected into function environment
   - No manual credential management

   **For Local Development:**
   - Use named profiles with `aws configure`
   - Store in `~/.aws/credentials`
   - Use `AWS_PROFILE` environment variable to select profile

   **Outside AWS (Applications on Other Servers):**
   - Use environment variables in deployment
   - Use named profiles from `~/.aws/credentials`
   - Implement credential rotation procedures

### Credential Rotation

- **Access Keys**: Rotate every 90 days minimum
- **IAM Users**: Create new key before deleting old one
- **Service Roles**: Automatic refresh of temporary credentials
- **Temporary Credentials**: Automatically invalidated after session ends

### Audit and Monitoring

- Use **IAM Credentials Report** to track key age and usage
- Use **IAM Access Advisor** to see service permissions and last access time
- Enable **CloudTrail** logging to audit API calls with their authentication method
- Regularly review which IAM users have active access keys

### Environment Variable Naming

Standard AWS environment variables (recognized by all SDKs):
- `AWS_ACCESS_KEY_ID` - Access key identifier
- `AWS_SECRET_ACCESS_KEY` - Secret access key
- `AWS_SESSION_TOKEN` - Temporary session token
- `AWS_REGION` or `AWS_DEFAULT_REGION` - Default region
- `AWS_PROFILE` - Named profile to use

---

## References

- [AWS CLI Configuration and Credential File Settings][1]
- [Configuring the AWS SDK for Java][2]
- [Boto3 Configuration][3]
- [IAM User Access Keys][4]
- [Temporary Security Credentials][5]

[1]: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html
[2]: https://docs.aws.amazon.com/sdk-for-java/latest/developer-guide/credentials.html
[3]: https://boto3.amazonaws.com/v1/documentation/api/latest/guide/credentials.html
[4]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html
[5]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp.html
