# AWS Service Limits and Rate Limiting

This document covers AWS API rate limits, service quotas, and how to handle throttling errors.

## Understanding API Rate Limits

AWS services have **API rate limits** to:
- Prevent abuse and denial-of-service attacks
- Ensure fair resource distribution across customers
- Maintain service stability and performance

Rate limits vary significantly by service and operation.

### Common Rate Limit Examples

**EC2 API:**
- `DescribeInstances`: 100 calls per second (per account, per region)

**S3 API:**
- `GetObject`: 5,500 GET requests per second per prefix
- `PutObject`: 3,500 PUT/COPY/POST/DELETE requests per second per prefix
- Partitions: Prefix is `/` prefix in key name for load distribution

**DynamoDB:**
- Provisioned: Read/write capacity units (throughput-based)
- On-Demand: Higher API call rate limits

**IAM:**
- Most operations: 100 calls per second

### How Rate Limiting Works

When you exceed a rate limit, AWS responds with an error:

**HTTP Status Code:** `429 Too Many Requests`

**Error Types:**
- `ThrottlingException` - rate limit exceeded (5xx server error for exponential backoff)
- `ProvisionedThroughputExceededException` - DynamoDB capacity exceeded
- `RequestLimitExceeded` - service-specific rate limit hit

```json
{
  "Error": {
    "Code": "ThrottlingException",
    "Message": "Rate exceeded"
  }
}
```

---

## Service Quotas (Service Limits)

**Service Quotas** (formerly called "service limits") are **per-account, per-region** limits on resources you can create or concurrent usage.

### Difference from API Rate Limits

| Aspect | API Rate Limits | Service Quotas |
|--------|-----------------|----------------|
| **What** | API call frequency | Resource creation/capacity |
| **Scope** | Per second | Per account per region |
| **Example** | 100 API calls/sec | 1152 vCPU for On-Demand instances |
| **Error** | ThrottlingException | LimitExceededException |
| **Increase** | Usually automatic or wait | Request via Service Quotas console |

### Common Service Quotas

**EC2:**
- Running On-Demand Standard Instances: 1152 vCPU (default)
- Running On-Demand T2 Instances: 10 vCPU (can vary)
- Elastic IPs: 5 per region
- Security Groups: 500 per VPC

**S3:**
- Buckets per account: 100 (soft limit, can increase)

**Lambda:**
- Concurrent executions: 1000 (per account, per region)
- Function size: 50 MB uncompressed

**RDS:**
- DB instances: 40 per account (default)

**DynamoDB:**
- Provisioned read/write capacity: Account-level limits

---

## Handling API Rate Limiting

### Error Types

**Intermittent Errors (Throttling):**
- Temporary rate limit exceeded
- Request might succeed if retried
- Use **Exponential Backoff**

**Consistent Errors (Over Quota):**
- Hitting service quota limit
- Request will fail until quota is increased
- Request **quota increase** or re-architecture

### Exponential Backoff

**Exponential Backoff** is a retry strategy where you:
1. Retry failed requests after a delay
2. Increase the delay between each retry (exponentially)
3. Add some randomness (jitter) to prevent thundering herd

### Implementation Rules

**DO:**
- ✓ Implement exponential backoff for **5xx errors** (server errors)
- ✓ Implement exponential backoff for **throttling exceptions**
- ✓ Use jitter to randomize retry timing
- ✓ Set maximum retry attempts (typically 3-5)

**DON'T:**
- ✗ Implement exponential backoff for **4xx errors** (client errors)
- ✗ Retry immediately without delay
- ✗ Use fixed delays (causes thundering herd)
- ✗ Retry indefinitely

### Why Not 4xx Errors?

4xx errors indicate client-side problems that won't be resolved by retrying:
- `400 Bad Request` - malformed request
- `403 Forbidden` - permission denied
- `404 Not Found` - resource doesn't exist
- `401 Unauthorized` - authentication failed

Retrying these will just waste resources.

### Exponential Backoff Examples

**Python with boto3:**

```python
import boto3
import random
import time

def call_with_exponential_backoff(func, max_attempts=5):
    base_delay = 1  # Start with 1 second
    
    for attempt in range(1, max_attempts + 1):
        try:
            return func()
        except Exception as e:
            # Check if error is retryable (5xx or throttling)
            if not is_retryable_error(e) or attempt == max_attempts:
                raise
            
            # Calculate delay with exponential backoff and jitter
            delay = base_delay * (2 ** (attempt - 1))  # exponential
            jitter = random.uniform(0, delay * 0.1)    # 10% jitter
            wait_time = delay + jitter
            
            print(f"Attempt {attempt} failed, retrying in {wait_time:.2f}s")
            time.sleep(wait_time)

def is_retryable_error(error):
    # Check error code
    error_code = getattr(error, 'response', {}).get('Error', {}).get('Code', '')
    
    # Retryable: 5xx errors and throttling
    retryable_codes = ['ThrottlingException', 'ServiceUnavailable', 'InternalError']
    return error_code in retryable_codes or error_code.startswith('5')

# Usage
s3_client = boto3.client('s3')

try:
    call_with_exponential_backoff(
        lambda: s3_client.list_objects(Bucket='my-bucket')
    )
except Exception as e:
    print(f"Failed after retries: {e}")
```

**AWS SDK Built-in Retry:**

The AWS SDK for many languages includes built-in exponential backoff:

```python
# boto3 automatically retries with exponential backoff
s3_client = boto3.client('s3')

# boto3 config with custom retry settings
from botocore.config import Config

config = Config(
    retries={'max_attempts': 10, 'mode': 'adaptive'}
)
s3_client = boto3.client('s3', config=config)
```

```javascript
// AWS SDK for JavaScript automatically retries
const s3 = new AWS.S3({
    maxRetries: 3,
    httpOptions: { timeout: 5000 }
});
```

---

## Requesting Quota Increases

### Using AWS Management Console

1. Go to **Service Quotas** console
2. Search for your service
3. Select the quota you want to increase
4. Click "Request quota increase"
5. Enter desired quota value
6. Submit request

### Using AWS CLI

```bash
# List current quotas for a service
aws service-quotas list-service-quotas \
    --service-code ec2 \
    --region us-east-1

# Request quota increase
aws service-quotas request-service-quota-increase \
    --service-code ec2 \
    --quota-code L-1216C47A \
    --desired-value 256
```

### Using API

```python
import boto3

quotas_client = boto3.client('service-quotas')

# Request increase
response = quotas_client.request_service_quota_increase(
    ServiceCode='ec2',
    QuotaCode='L-1216C47A',
    DesiredValue=256
)

request_id = response['RequestedServiceQuotaChange']['Id']
print(f"Request submitted: {request_id}")
```

### Typical Approval Timeline

- **Instant**: Some quota increases approved immediately
- **Minutes to Hours**: Most common for resource quotas
- **Up to 24 Hours**: More significant increases may require review
- **Business Days**: Some quotas may require manual approval

---

## Best Practices for Rate Limits

### Preventing Rate Limiting

1. **Batch Operations**
   - Use batch APIs when available
   - `BatchGetItem` for DynamoDB instead of multiple `GetItem` calls
   - `BatchWriteItem` for bulk writes

2. **Use Appropriate Concurrency**
   - Don't hammer with massive concurrent requests
   - Progressive increase if implementing new features
   - Monitor CloudWatch metrics

3. **Implement Caching**
   - Cache frequently accessed data
   - Reduces API calls
   - Use DAX for DynamoDB, ElastiCache for general use

4. **Design for Scalability**
   - Plan ahead for expected growth
   - Request quota increases before hitting limits
   - Use auto-scaling where available

### Monitoring and Alerting

**CloudWatch Metrics:**
```python
import boto3

cloudwatch = boto3.client('cloudwatch')

# Get throttled request count
response = cloudwatch.get_metric_statistics(
    Namespace='AWS/ApiGateway',
    MetricName='Count',
    StartTime='2023-03-15T00:00:00Z',
    EndTime='2023-03-16T00:00:00Z',
    Period=300,
    Statistics=['Sum'],
    Dimensions=[
        {'Name': 'ApiName', 'Value': 'my-api'},
        {'Name': 'Stage', 'Value': 'prod'}
    ]
)
```

**CloudWatch Alarms:**
Set up alarms for:
- API throttling exceptions
- High error rates
- Service quota utilization > 80%

---

## Exam Expectations

The AWS Developer exam expects you to:
- **Understand API rate limits** and their purpose
- **Know the difference** between rate limits and service quotas
- **Recognize `ThrottlingException`** as a retryable error
- **Implement exponential backoff** correctly in code
- **Know NOT to retry 4xx errors**
- **Request service quotas** when needed
- **Use AWS SDKs** which handle exponential backoff automatically

---

## References

- [API Rate Limits][1]
- [Service Quotas][2]
- [Exponential Backoff and Jitter][3]
- [CloudWatch Service Quotas][4]

[1]: https://docs.aws.amazon.com/general/latest/gr/api-throttling.html
[2]: https://docs.aws.amazon.com/servicequotas/latest/userguide/intro.html
[3]: https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
[4]: https://docs.aws.amazon.com/servicequotas/latest/userguide/intro.html
