# SQS vs SNS vs Kinesis — Comparison

Three services for decoupling applications, each with different semantics.

---

## At a Glance

| | SQS | SNS | Kinesis Data Streams |
|---|---|---|---|
| **Model** | Queue (pull) | Pub/sub (push) | Stream (pull or push) |
| **Consumers** | 1 message → 1 consumer | 1 message → all subscribers | 1 record → many consumers (replay) |
| **Ordering** | FIFO queue only | FIFO topic only | Per-shard (partition key) |
| **Retention** | Up to 14 days | None (deliver or lose) | Up to 365 days |
| **Replay** | No | No | Yes |
| **Throughput** | Unlimited (standard) | Unlimited | Per-shard limits |
| **Delivery** | At-least-once (standard), exactly-once (FIFO) | At-least-once | At-least-once |
| **Max message/record size** | 256 KB | 256 KB | 1 MB |

---

## Choosing the Right Service

### Use SQS when:

- You need to **decouple producers and consumers** with a buffer
- Consumers process messages **independently** (work queue pattern)
- You want **individual message delay** capability
- You need **dead letter queues** for failed processing
- Order doesn't matter (standard) or strict order within a group (FIFO)

Example: Order processing — each order is processed by one worker.

### Use SNS when:

- One event needs to reach **multiple subscribers** (fan-out)
- You want **push-based** delivery to diverse endpoints (email, SMS, HTTP, Lambda)
- You need **message filtering** per subscriber
- You're triggering multiple downstream systems from a single event

Example: Order placed → notify shipping, fraud detection, analytics (all receive the same event).

### Use Kinesis when:

- You need **real-time streaming** with low latency
- You need to **replay** data (reprocess historical events)
- Multiple consumers need to read the **same data independently**
- You need **ordering by partition key** at scale
- Data is high-volume and continuous (logs, clickstreams, IoT)

Example: Clickstream analytics — multiple consumers (real-time dashboard, ML, archival) read the same stream.

---

## Common Patterns

### Fan-Out (SNS + SQS)

Publish once to SNS; each SQS queue receives a copy for independent processing.

```
Publisher → SNS Topic → SQS Queue A (service A)
                      → SQS Queue B (service B)
                      → Lambda (service C)
```

Why not just multiple SQS queues? You'd have to publish to each queue separately. SNS decouples the publisher from knowing about all consumers.

### Event-Driven Processing (S3 → SNS → Multiple Consumers)

S3 events can only target one destination per event type + prefix. Use SNS to fan out.

```
S3 (object created) → SNS Topic → SQS (processing)
                                → Lambda (thumbnail)
                                → Firehose (archive)
```

### Real-Time Analytics (Kinesis)

High-volume data with multiple independent consumers.

```
Clickstream → Kinesis Data Streams → Lambda (real-time alerts)
                                   → Flink (aggregations)
                                   → Firehose → S3 (archive)
```

### Decoupled Microservices (SQS)

Each service owns a queue; other services send messages without blocking.

```
Order Service → SQS Queue → Inventory Service
              → SQS Queue → Payment Service
```

### FIFO Fan-Out (SNS FIFO + SQS FIFO)

When you need both ordering and fan-out.

```
Publisher → SNS FIFO Topic → SQS FIFO Queue A (ordered)
                           → SQS FIFO Queue B (ordered)
```

---

## Quick Decision Matrix

| Requirement | Service |
|---|---|
| Buffer messages for async processing | SQS |
| Fan-out to multiple consumers | SNS (+ SQS for durability) |
| Push notifications (email, SMS, mobile) | SNS |
| Real-time streaming with replay | Kinesis Data Streams |
| Load streaming data into S3/Redshift | Kinesis Data Firehose |
| Complex stream processing (SQL, joins) | Managed Service for Apache Flink |
| Strict ordering | SQS FIFO, SNS FIFO, or Kinesis (partition key) |
| Dead letter queue | SQS |
| Message filtering per subscriber | SNS |

---

## References

1. [Amazon SQS Developer Guide](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/)
2. [Amazon SNS Developer Guide](https://docs.aws.amazon.com/sns/latest/dg/)
3. [Amazon Kinesis Data Streams Developer Guide](https://docs.aws.amazon.com/streams/latest/dev/)
