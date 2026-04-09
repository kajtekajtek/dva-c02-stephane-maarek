# Amazon SNS — Simple Notification Service

Fully managed pub/sub messaging. Publishers send messages to a **topic**; all subscribers receive a copy.

```
Publisher → SNS Topic → Subscriber 1
                      → Subscriber 2
                      → Subscriber 3
```

---

## Core Concepts

**Topic** — a logical channel. Publishers send messages here; subscribers listen.
- Up to 100,000 topics per account
- Up to 12,500,000 subscriptions per topic

**Subscription** — a destination that receives messages from a topic.

Supported subscription protocols:
- SQS
- Lambda
- HTTP/HTTPS endpoints
- Email / Email-JSON
- SMS
- Mobile push (APNS, FCM, ADM)
- Kinesis Data Firehose

---

## Publishing

### Topic Publish (SDK)

Standard flow for backend systems:

```python
sns.publish(
    TopicArn='arn:aws:sns:us-east-1:123456789012:OrderTopic',
    Message='{"orderId": 1234}',
    Subject='New Order'  # optional, for email
)
```

### Direct Publish (Mobile)

For mobile push notifications:

1. Create a platform application (APNS, FCM, etc.)
2. Create platform endpoints for each device
3. Publish directly to the endpoint

---

## Fan-Out Pattern

SNS + SQS together. One message published to SNS is delivered to multiple SQS queues for independent processing.

```
Publisher → SNS Topic → SQS Queue A (fraud detection)
                      → SQS Queue B (shipping)
                      → SQS Queue C (analytics)
```

Benefits:
- Fully decoupled — add/remove subscribers without changing publisher
- Each queue processes independently with its own retry/DLQ logic
- Cross-region delivery supported (SQS queues in other regions)

**Requirement:** SQS queue access policy must allow SNS to send messages.

### S3 Events to Multiple Queues

S3 event notifications can only target one destination per event type + prefix combination. Use fan-out to send to multiple queues:

```
S3 (object created) → SNS Topic → SQS Queue 1
                                → SQS Queue 2
                                → Lambda
```

---

## Message Filtering

By default, all subscribers receive all messages. Use **filter policies** (JSON) to route messages to specific subscribers based on message attributes.

```json
{
  "state": ["placed"]
}
```

Messages with `state=placed` are delivered; others are filtered out for that subscription.

```
Publisher → SNS Topic
              ├── SQS (filter: state=placed)      → receives only "placed" orders
              ├── SQS (filter: state=cancelled)   → receives only "cancelled" orders
              └── SQS (no filter)                 → receives all messages
```

Filter policies are set on each subscription, not on the topic.

---

## FIFO Topics

SNS FIFO topics guarantee ordering and deduplication, similar to SQS FIFO.

- Topic name must end with `.fifo`
- Ordering by `MessageGroupID`
- Deduplication by `MessageDeduplicationID` or content-based
- Limited throughput (same as SQS FIFO: 300–3000 msg/s)

**FIFO fan-out:** SNS FIFO → SQS FIFO queues (ordering preserved end-to-end)

```
Publisher → SNS FIFO Topic → SQS FIFO Queue A
                           → SQS FIFO Queue B
```

Can also subscribe standard SQS queues to a FIFO topic (ordering not guaranteed in that case).

---

## Security

### Encryption

- **In-flight**: HTTPS
- **At-rest**: KMS encryption
- **Client-side**: Application encrypts before publishing

### Access Control

- **IAM policies**: Control who can publish/subscribe
- **SNS Access Policies** (resource-based): Cross-account access or allow AWS services

Example: Allow S3 to publish to the topic:

```json
{
  "Effect": "Allow",
  "Principal": {"Service": "s3.amazonaws.com"},
  "Action": "sns:Publish",
  "Resource": "arn:aws:sns:us-east-1:123456789012:MyTopic",
  "Condition": {
    "ArnLike": {"aws:SourceArn": "arn:aws:s3:::my-bucket"}
  }
}
```

---

## AWS Service Integrations

Many AWS services can publish directly to SNS:

- CloudWatch Alarms
- AWS Budgets
- Auto Scaling Groups (notifications)
- S3 Event Notifications
- DynamoDB Streams (via Lambda)
- CloudFormation (stack events)
- RDS Events
- CodePipeline / CodeBuild
- And many more...

---

## Delivery to Kinesis Data Firehose

SNS can deliver messages directly to Kinesis Data Firehose, enabling archival to S3, Redshift, or OpenSearch without custom code.

```
Publisher → SNS Topic → Kinesis Data Firehose → S3
```

Useful for event archival and analytics pipelines.

---

## References

1. [Amazon SNS Developer Guide](https://docs.aws.amazon.com/sns/latest/dg/)
2. [SNS Message Filtering](https://docs.aws.amazon.com/sns/latest/dg/sns-message-filtering.html)
3. [SNS FIFO Topics](https://docs.aws.amazon.com/sns/latest/dg/sns-fifo-topics.html)
