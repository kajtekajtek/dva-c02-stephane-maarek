# Amazon Kinesis

Family of services for real-time streaming data. Collect, process, and analyze data as it arrives.

---

## Kinesis Data Streams

Managed service for ingesting and storing streaming data in real-time.

```
Producers → Shards → Consumers
           (ordered)
```

### Key Characteristics

| Attribute | Value |
|---|---|
| Retention | 24 hours default, up to 365 days |
| Message size | Up to 1 MB per record |
| Ordering | Guaranteed within a shard (by partition key) |
| Replay | Yes — consumers can reprocess data |
| Deletion | Data cannot be deleted; expires after retention period |
| Encryption | At-rest (KMS), in-flight (HTTPS) |

### Capacity Modes

**Provisioned Mode:**
- You choose the number of shards
- Each shard: 1 MB/s in (1000 records/s), 2 MB/s out
- Pay per shard-hour
- Scale manually by splitting/merging shards

**On-Demand Mode:**
- No capacity planning required
- Default: 4 MB/s in (4000 records/s)
- Auto-scales based on throughput peak over last 30 days
- Pay per stream-hour + data in/out

### Shards and Partition Keys

Data is distributed across shards using a **partition key** (hashed). Records with the same partition key always go to the same shard → ordering is guaranteed per key.

```
Partition Key: "user-123" → always Shard 2
Partition Key: "user-456" → always Shard 1
```

### Producers

- **AWS SDK**: `PutRecord` (single), `PutRecords` (batch)
- **Kinesis Producer Library (KPL)**: High-performance batching, compression, retries
- **Kinesis Agent**: Daemon for log file ingestion

### Consumers

**Standard Consumer (Pull):**
- Uses `GetRecords` API with shard iterator
- Shared throughput: 2 MB/s per shard across all consumers
- ~200 ms latency

**Enhanced Fan-Out (Push):**
- Uses `SubscribeToShard` API (HTTP/2 push)
- Dedicated throughput: 2 MB/s per shard **per consumer**
- ~70 ms latency
- Up to 20 consumers per stream (50 with On-Demand Advantage) [1]

```
Standard:    Shard → 2 MB/s shared by Consumer A, B, C
Enhanced:    Shard → 2 MB/s to Consumer A
                   → 2 MB/s to Consumer B
                   → 2 MB/s to Consumer C
```

**Kinesis Client Library (KCL):**
- Handles shard discovery, checkpointing, load balancing
- One worker per shard (uses DynamoDB for coordination)
- Recommended for building consumer applications

---

## Amazon Data Firehose

*(Formerly Kinesis Data Firehose)*

Fully managed service for loading streaming data into destinations. No code required — configure and it runs.

```
Source → Data Firehose → Destination
                ↓
          (optional) Lambda transform
                ↓
           S3 backup
```

### Key Characteristics

| Attribute | Value |
|---|---|
| Management | Fully managed, serverless |
| Latency | Near real-time (buffering: 1–15 minutes or 1–128 MB) |
| Data storage | None — delivers immediately |
| Replay | Not supported |
| Scaling | Automatic |

### Sources

- Kinesis Data Streams
- Direct PUT (SDK, Kinesis Agent)
- CloudWatch Logs
- AWS IoT
- Other AWS services

### Destinations

**AWS:**
- Amazon S3
- Amazon Redshift (via S3)
- Amazon OpenSearch Service

**Third-party:**
- Splunk
- Datadog
- MongoDB
- New Relic
- HTTP endpoints

### Transformations

- Convert formats (CSV → Parquet/ORC)
- Compress (gzip, Snappy)
- Custom transformation via **Lambda function** (e.g., enrich, filter, convert)

### Backup

Configure S3 backup for:
- All records
- Only failed records

---

## Managed Service for Apache Flink

*(Formerly Kinesis Data Analytics for Apache Flink)*

Run Apache Flink applications on managed infrastructure for complex stream processing.

```
Kinesis Data Streams ─┐
                      ├→ Apache Flink Application → Output
Amazon MSK (Kafka) ───┘
```

### Key Characteristics

- Write in Java, Scala, or SQL (Flink SQL)
- Automatic scaling, checkpoints, snapshots
- Full Flink programming model (windows, joins, aggregations)
- **Does not read from Data Firehose** — use Data Streams or MSK as source

Use cases:
- Real-time analytics dashboards
- Anomaly detection
- ETL with complex transformations
- Time-windowed aggregations

---

## When to Use What

| Service | Use Case |
|---|---|
| **Data Streams** | Real-time ingestion with replay, custom consumers, multiple readers |
| **Data Firehose** | Simple ETL/delivery to S3, Redshift, OpenSearch; no custom code |
| **Managed Flink** | Complex stream processing, SQL analytics, joins, windowing |

---

## Data Streams vs Data Firehose

| | Data Streams | Data Firehose |
|---|---|---|
| Management | You manage shards (or use on-demand) | Fully managed |
| Latency | Real-time (~200ms or ~70ms with EFO) | Near real-time (buffered) |
| Storage | Up to 365 days | None |
| Replay | Yes | No |
| Consumers | Custom code (SDK, KCL, Lambda) | Managed delivery |
| Destinations | Anything (you write consumer) | S3, Redshift, OpenSearch, HTTP, Splunk, etc. |
| Scaling | Manual shard management or on-demand | Automatic |

---

## References

1. [Amazon Kinesis Data Streams Developer Guide](https://docs.aws.amazon.com/streams/latest/dev/)
2. [Amazon Data Firehose Developer Guide](https://docs.aws.amazon.com/firehose/latest/dev/)
3. [Enhanced Fan-Out](https://docs.aws.amazon.com/streams/latest/dev/enhanced-consumers.html)
4. [Managed Service for Apache Flink](https://docs.aws.amazon.com/managed-service-apache-flink/)
