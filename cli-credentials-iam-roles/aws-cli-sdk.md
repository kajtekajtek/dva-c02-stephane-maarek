# AWS CLI and SDK

## AWS CLI Overview

The **AWS Command Line Interface (CLI)** is a unified tool for interacting with AWS services from your terminal or command-line shell.

### Key Characteristics

- **Direct API Access**: Provides direct access to the public APIs of AWS services
- **Scripting**: Enables automation and batch operations through shell scripts
- **Cross-Platform**: Works on Linux, macOS, and Windows
- **Open Source**: Source code available on [GitHub](https://github.com/aws/aws-cli)
- **Built on AWS SDK**: The AWS CLI itself is built using the Python SDK (boto3)
- **Alternative to Console**: Provides command-line alternative to the AWS Management Console

### Core Use Cases

- Infrastructure automation and management
- CI/CD pipeline integration
- Batch operations and data processing
- Local development and testing
- Scripted deployments

### Basic Command Structure

```bash
aws service command [options]

# Examples
aws ec2 describe-instances --region us-east-1
aws s3 ls s3://my-bucket/
aws iam list-users
```

---

## AWS SDK Overview

The **AWS Software Development Kit (SDK)** is a set of language-specific libraries that enable programmatic access to AWS services directly from application code.

### Purpose

- **Embed AWS functionality** directly into your applications
- **Access and manage** AWS resources programmatically
- **Language-native interfaces** for more natural code integration
- **Handle low-level details** like request signing and retry logic

### Supported Languages

**Server SDKs:**
- Java
- Python (boto3 / botocore)
- .NET (C#)
- Node.js (JavaScript)
- Go
- Ruby
- PHP
- C++

**Mobile SDKs:**
- Android SDK
- iOS SDK
- React Native
- Flutter

**IoT Device SDKs:**
- Embedded C
- Arduino

### When to Use SDK vs CLI

| Use Case | SDK | CLI |
|----------|-----|-----|
| Application code needs AWS access | ✓ | |
| Automation scripts and batch jobs | ✓ | ✓ |
| Infrastructure provisioning | | ✓ |
| Local testing and development | ✓ | ✓ |
| Real-time API calls from code | ✓ | |
| Database operations (DynamoDB, etc.) | ✓ | Limited |
| Microservices and Lambda functions | ✓ | |

### Common SDK Usage Examples

**Python (boto3):**
```python
import boto3

s3_client = boto3.client('s3')
response = s3_client.list_buckets()

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('MyTable')
table.put_item(Item={'id': '123', 'name': 'Test'})
```

**Node.js:**
```javascript
const AWS = require('aws-sdk');
const s3 = new AWS.S3();

s3.listBuckets((err, data) => {
  if (err) console.error(err);
  else console.log(data.Buckets);
});
```

### Exam Expectation

The AWS Certified Developer exam expects you to:
- **Know when to use an SDK** vs. CLI vs. Management Console
- **Understand SDK credential handling** and provider chains
- **Be familiar with service-specific SDKs** (e.g., boto3 for DynamoDB operations)
- **Recognize SDK integration patterns** in Lambda functions and containerized applications

---

## References

- [AWS CLI Official Documentation][1]
- [AWS CLI GitHub Repository][2]
- [AWS SDK Documentation][3]
- [AWS Command Line Interface vs AWS SDK][4]

[1]: https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html
[2]: https://github.com/aws/aws-cli
[3]: https://docs.aws.amazon.com/sdkref/latest/guide/overview.html
[4]: https://docs.aws.amazon.com/prescriptive-guidance/latest/choose-tools-for-aws-development/cli-vs-sdk.html
