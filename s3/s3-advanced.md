# Amazon S3 Advanced Features

This document covers advanced S3 features including lifecycle management, performance optimization, events, and object metadata.

## S3 Lifecycle Management

**S3 Lifecycle** rules automate the management of object lifecycles by defining actions to transition objects between storage classes or delete them based on age or other criteria.

### What is Lifecycle Management?

Lifecycle rules enable you to:
- **Transition objects** between storage classes automatically
- **Expire (delete) objects** after a specified time
- **Optimize costs** by moving infrequently accessed data to cheaper storage
- **Maintain compliance** with data retention requirements

### Transition Actions

**Transition Actions** move objects from one storage class to another as they age.

#### Common Transition Paths

```
Standard
   ↓ (60 days)
Standard-IA
   ↓ (180 days)
Glacier Instant Retrieval
   ↓ (365 days)
Glacier Deep Archive
```

#### Transition Rules Example

```json
{
  "Rules": [
    {
      "Id": "TransitionToIA",
      "Status": "Enabled",
      "Transitions": [
        {
          "Days": 60,
          "StorageClass": "STANDARD_IA"
        },
        {
          "Days": 180,
          "StorageClass": "GLACIER"
        },
        {
          "Days": 365,
          "StorageClass": "DEEP_ARCHIVE"
        }
      ]
    }
  ]
}
```

#### Transition Rules

- Can create rules for a **specific prefix** (e.g., `s3://mybucket/logs/*`)
- Can create rules for objects with **specific tags** (e.g., objects tagged with `Archive: true`)
- **Minimum storage duration** applies:
  - Standard-IA: 30 days minimum
  - Glacier Instant Retrieval: 90 days minimum
  - Glacier Flexible Retrieval: 90 days minimum
  - Glacier Deep Archive: 180 days minimum
- Transitioning before minimum duration incurs extra charges

### Expiration Actions

**Expiration Actions** automatically delete objects after a specified time.

#### Common Use Cases

- Delete old **access logs** after 365 days
- Delete **temporary files** after specified duration
- Clean up **old versions** of objects (with versioning enabled)
- Remove **incomplete multi-part uploads**

#### Expiration Rules Example

```json
{
  "Rules": [
    {
      "Id": "DeleteOldLogs",
      "Status": "Enabled",
      "Prefix": "logs/",
      "Expiration": {
        "Days": 365
      }
    },
    {
      "Id": "DeleteIncompleteUploads",
      "Status": "Enabled",
      "AbortIncompleteMultipartUpload": {
        "DaysAfterInitiation": 7
      }
    }
  ]
}
```

### Lifecycle Rules with Versioning

When versioning is enabled, you can manage both **current** and **noncurrent** versions:

#### Noncurrent Version Transitions

Move previous versions to cheaper storage classes:

```json
{
  "Id": "ManageNoncurrentVersions",
  "Status": "Enabled",
  "NoncurrentVersionTransitions": [
    {
      "NoncurrentDays": 30,
      "StorageClass": "STANDARD_IA"
    },
    {
      "NoncurrentDays": 90,
      "StorageClass": "GLACIER"
    }
  ],
  "NoncurrentVersionExpiration": {
    "NoncurrentDays": 365
  }
}
```

### Lifecycle Rules Scenario 1: Image Thumbnails

**Scenario:** Your EC2 application generates image thumbnails after photo uploads. Thumbnails can be recreated easily and only need to be kept for 60 days. Source images should be immediately retrievable for 60 days, then can have 6-hour retrieval latency.

**Solution:**
- **Source images** in Standard with lifecycle to transition to Glacier after 60 days
  - Glacier provides retrieval latency of 1-5 minutes (acceptable for 6-hour requirement)
- **Thumbnails** in One-Zone IA with lifecycle to expire (delete) after 60 days
  - One-Zone IA is cheaper than Standard-IA
  - Thumbnails are ephemeral and can be regenerated

```json
{
  "Rules": [
    {
      "Id": "SourceImages",
      "Prefix": "source/",
      "Status": "Enabled",
      "Transitions": [
        {
          "Days": 60,
          "StorageClass": "GLACIER"
        }
      ]
    },
    {
      "Id": "Thumbnails",
      "Prefix": "thumbnails/",
      "Status": "Enabled",
      "Expiration": {
        "Days": 60
      }
    }
  ]
}
```

### Lifecycle Rules Scenario 2: Data Recovery

**Scenario:** Recover deleted S3 objects immediately for 30 days (happens rarely). After 30 days and for up to 365 days, recover deleted objects within 48 hours.

**Solution:**
- Enable **S3 Versioning** so deleted objects become delete markers
- Transition **noncurrent versions** to Standard-IA at 30 days
- Transition **noncurrent versions** to Glacier Deep Archive at 365 days

```json
{
  "Rules": [
    {
      "Id": "RecoveryLifecycle",
      "Status": "Enabled",
      "NoncurrentVersionTransitions": [
        {
          "NoncurrentDays": 30,
          "StorageClass": "STANDARD_IA"
        },
        {
          "NoncurrentDays": 365,
          "StorageClass": "DEEP_ARCHIVE"
        }
      ]
    }
  ]
}
```

---

## S3 Analytics – Storage Class Analysis

**S3 Analytics** helps you determine optimal lifecycle policies by analyzing access patterns.

### How It Works

- Analyzes storage and access patterns in your bucket
- Generates CSV reports with recommendations
- Reports updated daily
- Takes 24-48 hours to start seeing data analysis

### Limitations

- **Works for:** Standard and Standard-IA
- **Does NOT work for:** One-Zone IA or Glacier

### Reports Included

Storage analysis report includes:
- **DateStamp**: When the report was generated
- **StorageClass**: Storage class of analyzed objects
- **ObjectAge**: Age of objects in days
- Recommendations for transitioning to cheaper storage

### Using Reports

1. Enable S3 Analytics for bucket or prefix
2. Wait 24-48 hours for initial analysis
3. Review CSV report
4. Use insights to create or optimize lifecycle rules

```
DateStamp   StorageClass  ObjectAge
2023-08-22  STANDARD      000-014 days
2023-08-25  STANDARD      030-044 days
2023-09-06  STANDARD      120-149 days
```

---

## S3 Event Notifications

**S3 Event Notifications** trigger actions when events occur on S3 objects (upload, delete, restore, replication).

### Event Types

- `S3:ObjectCreated`: Put, Post, Copy, CompleteMultipartUpload
- `S3:ObjectRemoved`: Delete (with or without version ID)
- `S3:ObjectRestore`: Restore from Glacier
- `S3:Replication`: Replication events

### Notification Destinations

S3 can notify various AWS services when events occur:

```
S3 Bucket
    ↓
    ├─→ SNS Topics (pub/sub)
    ├─→ SQS Queues (message queue)
    ├─→ Lambda Functions (trigger code)
    └─→ EventBridge (advanced filtering & routing)
```

### Key Characteristics

- **Typical latency**: Events delivered in seconds (sometimes up to 1 minute)
- **Object name filtering**: Can filter by object key patterns (e.g., `*.jpg`)
- **Flexibility**: Create as many event notifications as needed

### Resource Permissions Required

Each destination requires appropriate **resource-based policies**:

```
SNS Resource Policy      SQS Resource Policy      Lambda Resource Policy
(Allow S3 to publish)    (Allow S3 to send msg)   (Allow S3 to invoke)
```

Example SNS Resource Policy:
```json
{
  "Effect": "Allow",
  "Principal": {
    "Service": "s3.amazonaws.com"
  },
  "Action": "SNS:Publish",
  "Resource": "arn:aws:sns:us-east-1:123456789012:my-topic",
  "Condition": {
    "StringEquals": {
      "aws:SourceAccount": "123456789012"
    },
    "ArnLike": {
      "aws:SourceArn": "arn:aws:s3:::my-bucket"
    }
  }
}
```

### Use Case: Thumbnail Generation

```
1. User uploads photo to S3
2. S3:ObjectCreated event triggered
3. Event sent to Lambda function
4. Lambda generates thumbnail
5. Thumbnail uploaded to S3
6. Application notified via SNS
```

---

## S3 Event Notifications with EventBridge

**Amazon EventBridge** provides advanced event routing with more capabilities than native S3 notifications.

### Advantages over Native S3 Events

- **Advanced filtering**: JSON rules with metadata, object size, object name
- **Multiple destinations**: Step Functions, Kinesis Streams, Firehose, etc.
- **Over 18 AWS services** supported as targets
- **Event replay**: Re-process events from the past
- **Event archive**: Persistent storage of events
- **Reliable delivery**: Built-in retry logic

### Event Filtering Example

```json
{
  "source": ["aws.s3"],
  "detail-type": ["Object Created"],
  "detail": {
    "bucket": {
      "name": ["my-bucket"]
    },
    "object": {
      "key": [{
        "prefix": "uploads/photos/"
      }],
      "size": [{
        "numeric": [">", 1000000]
      }]
    }
  }
}
```

This rule matches:
- Objects in `my-bucket`
- Under `uploads/photos/` prefix
- Larger than 1MB

### Architecture Example

```
S3 Bucket Events
    ↓
EventBridge
    ├─→ Rule 1: Archive to S3 (with EventBridge archive)
    ├─→ Rule 2: Process with Lambda
    ├─→ Rule 3: Send to Kinesis Stream
    ├─→ Rule 4: Trigger Step Functions
    └─→ Rule 5: Store in DynamoDB
```

---

## S3 Performance Optimization

### Baseline Performance

**Automatic Scaling:**
- S3 automatically scales to high request rates
- Achieves latency of 100-200ms
- Per prefix performance: 3,500 PUT/COPY/POST/DELETE or 5,500 GET/HEAD requests **per second per partitioned Amazon S3 prefix**

### Request Distribution Across Prefixes

To achieve higher throughput, distribute requests across multiple prefixes:

```
Bucket structure:
/folder1/sub1/file → prefix: /folder1/sub1/
/folder1/sub2/file → prefix: /folder1/sub2/
/2/file → prefix: /2/
/1/file → prefix: /1/
```

**Performance calculation:**
- 4 prefixes × 5,500 GET/HEAD per second = 22,000 GET/HEAD requests per second total

### Multi-Part Upload

**When to use:**
- Files > 100MB (recommended)
- Files > 5GB (required)

**Benefits:**
- Parallelizes uploads across parts
- Faster transfer speeds
- Can retry failed parts without re-uploading entire file
- Enables concurrent uploads

```
Big File
    ↓
Divide into Parts
    ↓
Parallel Upload
    ↓
Combine in S3
```

### S3 Transfer Acceleration

**What it does:**
- Routes uploads/downloads through CloudFront edge locations
- Transfers to AWS edge location via public internet (fast)
- Forwarded to S3 bucket via private AWS network (reliable)

**Benefits:**
- Increases upload/download speeds
- Compatible with multi-part upload
- Best for geographically distributed clients

**Use case:**
User uploading file from Australia to S3 bucket in USA:
```
Australia User
    ↓ (Fast Public Internet)
US Edge Location
    ↓ (Private AWS Network)
S3 Bucket USA
```

**Configuration:**
```bash
# AWS CLI with Transfer Acceleration
aws s3 cp large-file.zip s3://my-bucket/ \
  --region us-east-1 \
  --endpoint-url https://my-bucket.s3-accelerate.amazonaws.com
```

```python
# Python SDK
s3_client = boto3.client(
    's3',
    config=Config(s3={'use_accelerate_endpoint': True})
)
```

---

## S3 Byte-Range Fetches

**Byte-Range Fetches** allow you to request specific byte ranges of an object, enabling parallel downloads and partial retrieval.

### Use Cases

1. **Parallel downloads**: Request different byte ranges in parallel
   - Faster overall retrieval
   - Better resilience to failures

2. **Partial retrieval**: Get only the data you need
   - Request just the header of a large file
   - Reduce bandwidth usage

### How It Works

```
File in S3 (1000 bytes)
├─ Part 1: bytes 0-249
├─ Part 2: bytes 250-499
├─ Part 3: bytes 500-749
└─ Part 4: bytes 750-999

All parts requested in parallel via byte-range requests
```

### Examples

**Retrieve first 1000 bytes (header):**
```bash
aws s3api get-object \
  --bucket my-bucket \
  --key large-file.bin \
  --range bytes=0-999 \
  output-file.bin
```

**Python SDK:**
```python
import boto3

s3_client = boto3.client('s3')

# Get first 1000 bytes
response = s3_client.get_object(
    Bucket='my-bucket',
    Key='large-file.bin',
    Range='bytes=0-999'
)

data = response['Body'].read()
```

**Parallel byte-range retrieval:**
```python
import boto3
from concurrent.futures import ThreadPoolExecutor

s3_client = boto3.client('s3')
bucket = 'my-bucket'
key = 'large-file.bin'
object_size = 1000000  # 1MB
chunk_size = 250000    # 250KB chunks

def download_chunk(start):
    end = min(start + chunk_size - 1, object_size - 1)
    response = s3_client.get_object(
        Bucket=bucket,
        Key=key,
        Range=f'bytes={start}-{end}'
    )
    return response['Body'].read()

with ThreadPoolExecutor(max_workers=4) as executor:
    futures = []
    for start in range(0, object_size, chunk_size):
        futures.append(executor.submit(download_chunk, start))
    
    chunks = [f.result() for f in futures]
    file_data = b''.join(chunks)
```

---

## S3 Object Metadata and Tags

### Object Metadata

**User-Defined Metadata:**
- Key-value pairs assigned when uploading an object
- Names must begin with `x-amz-meta-` prefix
- Amazon S3 stores names in lowercase
- Retrieved when accessing the object

```
Header: x-amz-meta-origin → Value: paris
Header: x-amz-meta-department → Value: engineering
```

**System Metadata:**
- Automatically set by S3
- Examples: Content-Length, Content-Type, ETag

### Object Tags

**Purpose:**
- Key-value pairs for S3 objects
- Different from metadata
- Useful for fine-grained permissions and analytics

**Use Cases:**
1. **Fine-grained permissions**: Only allow access to objects with specific tags
   ```json
   {
     "Effect": "Allow",
     "Action": "s3:GetObject",
     "Resource": "arn:aws:s3:::my-bucket/*",
     "Condition": {
       "StringEquals": {
         "s3:ExistingObjectTag/Department": "Finance"
       }
     }
   }
   ```

2. **Analytics**: Group objects by tags for analysis
   - Cost allocation
   - Usage tracking
   - Lifecycle management

### Metadata vs Tags

| Aspect | Metadata | Tags |
|--------|----------|------|
| **Purpose** | Store object info | Categorization & permissions |
| **Naming** | x-amz-meta- prefix | Simple key-value |
| **Searchable** | No | No |
| **Use Cases** | Origin, format, etc. | Permissions, billing, analytics |

### Searching Objects by Metadata/Tags

**Important:** S3 does NOT support searching objects by metadata or tags directly.

**Solution:** Use external database as search index:
```
S3 Objects
    ↓ (When object uploaded)
Lambda Function
    ↓
Extract metadata/tags
    ↓
DynamoDB Table (searchable index)
    ↓
Application queries DynamoDB
```

Example DynamoDB index table:
```
PK: bucket#object_id
SK: timestamp
Attributes:
  - bucket_name
  - object_key
  - object_size
  - tags (mapped)
  - metadata (mapped)
  - content_type
```

---

## References

- [S3 Lifecycle Policies][1]
- [S3 Analytics][2]
- [S3 Event Notifications][3]
- [S3 Performance Best Practices][4]
- [S3 Object Metadata][5]

[1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html
[2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/analytics-storage-class.html
[3]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/EventNotifications.html
[4]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/performance-optimization.html
[5]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingMetadata.html
