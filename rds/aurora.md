# Amazon Aurora

## Aurora

- Proprietary, fully managed relational engine compatible with **MySQL** and **PostgreSQL** — existing tools, drivers, and apps largely work unchanged
- Part of **Amazon RDS** (Console, CLI, API for provision, patch, backup, recovery, failure detection, repair)
- Customized engines + **distributed storage subsystem** — AWS docs: up to **~5×** MySQL throughput and **~3×** PostgreSQL throughput for some workloads (no app changes for most cases)
- **Storage auto-grows** — cluster volume up to **128 TiB**
- Operations target **clusters** (replicated, synchronized DB servers), not only single instances

## Aurora High Availability and Read Scaling

**Data (storage layer)**

- Cluster volume spans **multiple AZs**; each AZ has a copy of cluster data
- Writes from primary with **synchronous** replication to **six storage nodes** across AZs
    - 4 / 6 copies needed for writes
    - 3 / 6 copies need for reads
    - Self healing with peer-to-peer replication
    - Storage is striped across 100s of volumes

**Instances (compute layer)**

- **Writer (primary)** — reads + writes; one per cluster
- **Aurora Replicas (readers)** — read-only; up to **15** per cluster; **async** replication to instances for HA without hammering primary performance
- **Reader endpoint** — connection load-balancing across replicas for `SELECT`-heavy workloads
- **Failover** — if writer fails: promote a replica (preferred) or create new primary; typically **&lt; 60 s**, often **&lt; 30 s** when promoting a replica; with **no replicas**, recovery can take **~&lt; 10 min** (new primary in same AZ)
- **Replica lag** — usually **&lt; 100 ms** after writer commit (varies with write rate)
- **Failover priority** — tiers **0** (highest)–**15** (lowest); same tier → larger instance wins, then arbitrary
- **Cross-Region** — **Aurora Global Database**: async replication to secondary Regions; low-latency global reads + DR
- **RDS Proxy** — optional; preserves connections through failover; can reduce failover time vs DNS caching alone

## Aurora DB Cluster

- **Components:** one or more **DB instances** + single **cluster volume** (shared data for all instances)
- **Writer** — sole instance that performs **DDL/DML** and writes to shared storage
- **Readers** — read-only; same logical storage as writer (minimal per-replica replication work vs copy-on-each-node model)
- **Single-instance cluster** still valid — storage layer is multi-AZ by design
- **Compute vs storage** — scaled independently; storage grows automatically

**Endpoints** (stable hostnames; no hardcoding every instance)

| Endpoint | Role |
| -------- | ---- |
| **Cluster** | Current **writer** — DDL, DML, ETL |
| **Reader** | Read queries; load-balanced across replicas |
| **Instance** | Specific instance (tuning, diagnosis) |
| **Custom** | Subset of instances (mixed instance sizes/configs) |
| **Global DB writer** | Global Database — tracks primary Region across switchover/failover |

## Features of Aurora

- MySQL/PostgreSQL compatibility + push-button migration from RDS MySQL/PostgreSQL (snapshots, one-way replication)
- Automatic storage growth to **128 TiB**
- Up to **15** read replicas, cross-AZ placement, configurable failover priority
- **Backtrack** (Aurora MySQL) — point-in-time rewind without restore from snapshot (where supported; see engine/Region matrices)
- **Parallel query** (where enabled) — offload analytics to parallel layer
- **Aurora Serverless** — v1/v2 auto-scaling compute options for variable workloads
- **Global Database** — multi-Region reads + fast regional disaster recovery
- Same RDS family: **VPC**, Security Groups, **IAM**, encryption, **Performance Insights**, etc.

## References

- [What is Amazon Aurora? — Amazon Aurora User Guide](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/CHAP_AuroraOverview.html)
- [Amazon Aurora DB clusters](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Overview.html)
- [High availability for Amazon Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.AuroraHighAvailability.html)
- [Replication with Amazon Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Replication.html)
- [Amazon Aurora endpoint connections](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Overview.Endpoints.html)
- [Using Amazon Aurora Global Database](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database.html)
