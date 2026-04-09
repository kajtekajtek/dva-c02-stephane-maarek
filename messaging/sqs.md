# Amazon SQS — Simple Queue Service

Fully managed message queue for decoupling applications. Producers send messages; consumers poll and process them asynchronously.

```
Producer → SQS Queue → Consumer(s)
```

---

## Standard Queue

Default queue type. Optimized for throughput over ordering.

| Attribute | Value |
|---|---|
| Throughput | Unlimited |
| Message size | Up to 256 KB (use Extended Client for larger) |
| Retention | 4 days default, 1 minute to 14 days configurable |
| Latency | < 10 ms publish/receive |
| Delivery | At-least-once (duplicates possible) |
| Ordering | Best-effort (out-of-order possible) |

---

## FIFO Queue

Guaranteed ordering and exactly-once processing. Queue name must end with `.fifo`.

| Attribute | Value |
|---|---|
| Throughput | 300 msg/s (3000 msg/s with batching) |
| Delivery | Exactly-once (deduplication) |
| Ordering | Strict FIFO within a Message Group |

### Message Group ID

All messages with the same `MessageGroupID` are delivered in order. Different group IDs can be processed in parallel by different consumers.

```
Group A: [A1] [A2] [A3] → Consumer 1 (in order)
Group B: [B1] [B2]      → Consumer 2 (in order)
```

### Deduplication

5-minute deduplication window. Two methods:
- **Content-based**: SHA-256 hash of message body
- **Explicit**: Provide `MessageDeduplicationID`

---

## Producing Messages

Use the `SendMessage` API (SDK). Message persists in queue until deleted by a consumer.

```python
sqs.send_message(
    QueueUrl=queue_url,
    MessageBody='{"orderId": 1234}',
    DelaySeconds=10,  # optional
    MessageGroupId='orders'  # required for FIFO
)
```

### Delay Queues

Messages become invisible for a delay period before consumers can see them.

- Queue-level default: `DelaySeconds` (0–900 seconds)
- Per-message override: `DelaySeconds` parameter on `SendMessage`

---

## Consuming Messages

Consumers poll with `ReceiveMessage`, process, then delete with `DeleteMessage`.

```python
messages = sqs.receive_message(
    QueueUrl=queue_url,
    MaxNumberOfMessages=10,  # 1–10
    WaitTimeSeconds=20       # long polling
)
for msg in messages.get('Messages', []):
    process(msg['Body'])
    sqs.delete_message(QueueUrl=queue_url, ReceiptHandle=msg['ReceiptHandle'])
```

### Short Polling vs Long Polling

| | Short Polling | Long Polling |
|---|---|---|
| Behavior | Returns immediately, queries subset of servers | Waits up to 20s, queries all servers |
| Empty responses | Frequent when queue is sparse | Only when timeout expires |
| Cost | Higher (more API calls) | Lower |
| Configuration | `WaitTimeSeconds=0` (default) | `WaitTimeSeconds=1–20` |

Set `ReceiveMessageWaitTimeSeconds` at queue level or override per request.

### Batch Operations

Reduce costs by batching up to 10 messages:
- `SendMessageBatch`
- `DeleteMessageBatch`
- `ChangeMessageVisibilityBatch`

---

## Visibility Timeout

When a message is received, it becomes invisible to other consumers for a period (default 30 seconds).

```
ReceiveMessage → (invisible for 30s) → if not deleted, message reappears
```

- If processing takes longer than timeout → message is delivered again (duplicate)
- Consumer can extend timeout with `ChangeMessageVisibility` API
- Too high: slow recovery if consumer crashes
- Too low: duplicates from slow processing

---

## Dead Letter Queue (DLQ)

Messages that fail processing repeatedly are moved to a DLQ for inspection.

Configure a **redrive policy** on the source queue:
- `maxReceiveCount`: how many times a message can be received before going to DLQ
- `deadLetterTargetArn`: ARN of the DLQ

Rules:
- Standard queue → Standard DLQ
- FIFO queue → FIFO DLQ
- Set DLQ retention to 14 days (messages may already be old when they arrive)

### Redrive to Source

After fixing bugs, redrive messages from the DLQ back to the original queue (Console or API) without writing custom code.

---

## Extended Client (Large Messages)

SQS max message size is 256 KB. For larger payloads (up to 2 GB), use the **SQS Extended Client Library** (Java):

1. Producer uploads large payload to S3
2. Producer sends a small metadata message to SQS (contains S3 pointer)
3. Consumer receives metadata, retrieves payload from S3

```
Producer → S3 (large payload)
        → SQS (pointer message)
Consumer ← SQS ← S3
```

---

## Security

### Encryption

- **In-flight**: HTTPS endpoints
- **At-rest**: KMS encryption (SSE-SQS or SSE-KMS)
- **Client-side**: Application encrypts before sending

### Access Control

- **IAM policies**: Control who can call SQS APIs
- **SQS Access Policies** (resource-based): Allow cross-account access or other AWS services

Example: Allow S3 to send event notifications to the queue:

```json
{
  "Effect": "Allow",
  "Principal": {"Service": "s3.amazonaws.com"},
  "Action": "sqs:SendMessage",
  "Resource": "arn:aws:sqs:us-east-1:111122223333:MyQueue",
  "Condition": {
    "ArnLike": {"aws:SourceArn": "arn:aws:s3:::my-bucket"}
  }
}
```

---

## Auto Scaling with SQS

A common pattern: scale consumers based on queue depth.

```
SQS Queue
    ↓
CloudWatch Metric: ApproximateNumberOfMessages
    ↓
CloudWatch Alarm → ASG scaling policy
    ↓
More/fewer EC2 instances polling the queue
```

Works with EC2 Auto Scaling Groups, ECS services, or Lambda (native integration).

---

## Key APIs

| API | Purpose |
|---|---|
| `CreateQueue` | Create queue (set `MessageRetentionPeriod`, `VisibilityTimeout`, etc.) |
| `DeleteQueue` | Delete queue |
| `PurgeQueue` | Delete all messages in queue |
| `SendMessage` | Send one message |
| `ReceiveMessage` | Poll for messages (up to 10) |
| `DeleteMessage` | Remove processed message |
| `ChangeMessageVisibility` | Extend/reduce visibility timeout |
| `GetQueueAttributes` | Get queue metadata |

---

## References

1. [Amazon SQS Developer Guide](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/)
2. [SQS FIFO Queues](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/FIFO-queues.html)
3. [SQS Long Polling](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-short-and-long-polling.html)
