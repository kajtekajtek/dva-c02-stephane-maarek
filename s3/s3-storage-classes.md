# S3 Storage Classes

## Durability and Availability

- Every object has a **storage class**; choice trades off **cost**, **performance**, and **availability** for your access pattern
- **Durability**: all classes are built for **high durability**: **99.999999999%** (11 nines)
- **Availability** and **AZ footprint** differ by class
- **Resilience to loss of an Availability Zone**: all classes except **S3 One Zone-IA** and **S3 Express One Zone** are designed to tolerate loss of an AZ; **One Zone-IA** and **Express One Zone** use a **single** AZ you select
- **Costs**: consider **storage**, **retrieval**, **minimum storage duration**, **minimum billable object size**, and **monitoring** fees where applicable [1]
- It's possible to **move objects between classes manually** or using **S3 Lifecycle configurations**

## Storage Classes

### Standard - General Purpose

- **Code**: `STANDARD`
- **Default** if you omit storage class on upload
- **Use**: frequently accessed data, **millisecond** latency
- **Designed for**: durability **99.999999999%**, availability **99.99%**, **3+** AZs
- **Minimum storage duration**: none (per comparison table)
- **S3 analytics – Storage Class Analysis** can inform moves toward **Standard-IA**

### Standard-Infrequent Access (IA)

- **Code**: `STANDARD_IA`
- **Use**: **long-lived**, **infrequently** accessed data; still **millisecond** access like Standard
- **Resilience**: redundant across **multiple** geographically separated **AZs** (similar to Standard)
- **Charges**: **per-GB retrieval** fees; optimize for data not read often
- **Examples**: backups, older data moved via **Lifecycle** from Standard
- **Minimums**: objects **larger than 128 KB** intended for **at least 30 days**; smaller objects billed as **128 KB**; early delete/overwrite/transition can incur **pro-rated** remainder of **30-day** minimum

### One Zone-Infrequent Access

- **Code**: `ONEZONE_IA`
- **Use**: **recreatable** data if the **AZ** is lost; **replicas** in **CRR** scenarios; **Local Zones** directory buckets for residency (see directory-bucket docs)
- **Storage**: **one** AZ only, so **lower cost** than Standard-IA but **not** resilient to loss of that AZ
- **Designed for**: same **durability** target as Standard-IA in the doc sense, but **lower availability** (**99.5%** in comparison table) and **less resilience**
- **Same minimums** pattern as Standard-IA: **30-day** minimum duration, **128 KB** minimum billable size, **retrieval** fees [1]

### Glacier Instant Retrieval

- **Code**: `GLACIER_IR`
- **Use**: long-term, **rarely** accessed data needing **millisecond** retrieval (e.g. quarterly access patterns)
- **Access**: **real-time** (not archival in the same sense as Flexible/Deep)
- **Compared to Standard-IA**: lower **storage** cost, higher **access** cost
- **Minimums**: **128 KB** object size minimum, **90-day** minimum storage duration

### Glacier Flexible Retrieval

- **Code**: `GLACIER`
- **Use**: archive accessed about **1-2 times per year**; **no** immediate access required
- **Archival**: objects **not** available for real-time access; **`RestoreObject`** creates a **temporary** copy for access
- **Retrieval tiers** (typical times in docs): **Expedited** ~**1–5 minutes**; **Standard** ~**3–5 hours** (Batch Operations variant documented separately); **Bulk** ~**5–12 hours** (bulk **free**)
- **Minimum storage duration**: **90 days**; extra **metadata** overhead per object (32 KB + 8 KB) billed per doc

### Glacier Deep Archive

- **Code**: `DEEP_ARCHIVE`
- **Use**: access **less than once a year**; compliance and long retention; lowest-cost S3 archive option in AWS docs
- **Archival**: restore required before use; **Standard** retrieval typically **~12 hours** (9–12 hours with Batch Operations per doc); **Bulk** typically **~48 hours**
- **Minimum storage duration**: **180 days**; same **40 KB** metadata pattern as Flexible Retrieval (32 KB + 8 KB) [2]

### Intelligent Tiering

- **Code**: `INTELLIGENT_TIERING`
- **Use**: **unknown or changing** access patterns; **no retrieval fees** (monitoring/automation fees per object apply)
- **Designed for**: **99.9%** availability, **99.999999999%** durability, **3+** AZs
- **Automatic tiers** (low latency / high throughput unless optional archive tiers used)
  - **Frequent Access**: default for new uploads
  - **Infrequent Access**: after **30** days without access
  - **Archive Instant Access**: after **90** days without access
- **Optional async archive tiers** (must **restore** before access): **Archive Access** (min **90** days without access after opt-in), **Deep Archive Access** (min **180** days)
- **Objects under 128 KB**: **not** monitored; stay in **Frequent Access** tier [1]

## References

- [Understanding and managing Amazon S3 storage classes at docs.aws.amazon.com][1]
- [Understanding S3 Glacier storage classes for long-term data storage at docs.aws.amazon.com][2]

[1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage-class-intro.html
[2]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/glacier-storage-classes.html
