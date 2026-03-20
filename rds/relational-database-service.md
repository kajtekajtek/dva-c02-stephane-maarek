# Relational Database Service

## Relational Database Service (RDS)

- **Managed** relational database service — AWS handles provisioning, patching, backups, failure detection, and recovery
- Runs on EC2 instances under the hood, but you **cannot SSH** into the underlying host
- Deployed inside a **VPC** (private subnets by default); access controlled via Security Groups
- Uses **Amazon EBS** for storage

**Supported engines:**

- MySQL
- PostgreSQL
- MariaDB
- Oracle Database
- Microsoft SQL Server
- IBM Db2

**Key capabilities:**

- Automated backups + point-in-time restore (up to 35 days)
- Manual DB snapshots (retained indefinitely)
- **Multi-AZ** deployments — synchronous standby replica in a different AZ; automatic failover
- **Read Replicas** — asynchronous replication; up to 15 replicas; offload read traffic
- IAM authentication support (MySQL, PostgreSQL)
- Monitoring via **CloudWatch** (metrics every 1 min), **Performance Insights**, Enhanced Monitoring

**DB Instance classes:**

- General purpose — `db.m`*
- Memory optimized — `db.z*`, `db.x*`, `db.r*`
- Compute optimized — `db.c*`
- Burstable — `db.t*`

**Billing:** on-demand or reserved instances; pay for instance + storage + I/O + backups

## RDS vs deploying a database on EC2


| Responsibility           | On-premises | EC2      | RDS      |
| ------------------------ | ----------- | -------- | -------- |
| Application optimization | Customer    | Customer | Customer |
| Query tuning             | Customer    | Customer | Customer |
| Scaling                  | Customer    | Customer | **AWS**  |
| High availability        | Customer    | Customer | **AWS**  |
| DB backups               | Customer    | Customer | **AWS**  |
| DB software patching     | Customer    | Customer | **AWS**  |
| DB software install      | Customer    | Customer | **AWS**  |
| OS patching              | Customer    | Customer | **AWS**  |
| OS installation          | Customer    | Customer | **AWS**  |
| Server maintenance       | Customer    | **AWS**  | **AWS**  |
| Hardware lifecycle       | Customer    | **AWS**  | **AWS**  |
| Power, network, cooling  | Customer    | **AWS**  | **AWS**  |


**Why RDS over EC2:**

- No manual OS/DB patching, no accidental downtime from manual updates
- Automated backup, HA, and failover out of the box
- Storage auto scaling, read replicas, Multi-AZ handled by AWS

**Why EC2 over RDS:**

- Full OS/DB control needed (custom patches, unsupported engines, special configs)
- Use cases requiring SSH access or non-standard DB software

## Storage Auto Scaling

- Automatically increases EBS storage when running low — no downtime, no manual intervention
- Must set a **Maximum Storage Threshold** (upper limit for auto scaling)
- Scaling is triggered when **all** conditions are met:
  - Free storage drops to **≤ 10%** of allocated storage
  - Low-storage condition lasts **≥ 5 minutes**
  - **≥ 6 hours** since last storage modification (or optimization has completed)
- Storage increases by the **greatest** of:
  - 10 GiB
  - 10% of currently allocated storage
  - Predicted storage need for the next 7 hours (based on past hour's metrics)
- Supported for all RDS engines
- Recommended: set threshold **≥ 26% above** current allocation to avoid threshold-approaching alerts
- **Not available** when storage optimization is in progress

## Read Replicas

### Read Replicas for Scalability

- Read-only copies of the primary DB instance
- Replication is **asynchronous** → reads are **eventually consistent** (replica may serve slightly stale data until it catches up with the primary)
- Up to **15 read replicas** per source instance (within same AZ, cross-AZ, or cross-Region)
- Applications connect to a replica just like any DB instance — must update connection strings to use replicas
- Replicas can be within the same AZ, a different AZ, or a different Region
- **Cannot** be used for write operations — read-only connections only (exceptions: Db2 standby mode, Oracle mounted mode — neither serve read traffic)
- RDS does **not** autoscale read replicas — must create/delete manually
- Replica storage type can differ from source (e.g., source on gp2, replica on io1)
- Can create a replica **from a replica** (MySQL, MariaDB, some PostgreSQL versions) — not supported for Db2, Oracle, SQL Server
- No circular replication — a replica cannot replicate back to its source
- Deleting source DB without deleting same-Region replicas → replicas are **promoted** to standalone instances

### Use Cases

- **Scale read traffic** — offload read-heavy workloads (analytics, reporting) from the primary instance
- **Reporting / data warehousing** — run business reporting queries against a replica instead of production DB
- **High availability during maintenance** — serve reads when primary is unavailable (e.g., I/O suspended during backup)
- **Disaster recovery** — promote a read replica to a standalone DB instance if primary fails
- **Cross-Region locality** — place replicas closer to users in other regions for lower read latency

### Network Cost

- **Same-Region replication** → **free** (no data transfer charges between source and replica within the same AWS Region)
- **Cross-Region replication** → **charged** — incurs standard AWS data transfer fees for:
    - Initial snapshot transfer to the target region
    - Ongoing replication of data modifications between regions
- Replicas are billed as standard DB instances at the same rate as their instance class

## Multi-AZ

### Multi-AZ for Disaster Recovery

- AWS automatically provisions and maintains a **synchronous standby replica** in a different AZ
- Replication is **synchronous** — writes are not acknowledged until both primary and standby have committed → **zero data loss**
- **One DNS endpoint** — applications always connect to the same endpoint; failover is transparent (no connection string change needed)
- Standby replica **cannot serve read traffic** — it exists solely for HA/failover (not a scaling solution)
- **Automatic failover** triggers on:
    - Primary host failure
    - AZ outage
    - DB instance OS patching / maintenance
    - Primary DB instance storage failure
- Failover mechanism: AWS updates the DNS CNAME (TTL ~5 sec) to point to the standby, which is promoted to primary
- Typical failover time: **60–120 seconds** (Multi-AZ DB instance)
- Multi-AZ DB instance deployment: **1 standby** (no read traffic)
- Multi-AZ DB cluster deployment: **2 standbys** in 3 AZs — standbys *can* serve read traffic
- May have slightly increased write/commit latency vs Single-AZ due to synchronous replication overhead → use **Provisioned IOPS** for production

### From Single-AZ to Multi-AZ

- **Zero downtime** operation — no need to stop the DB
- AWS performs the conversion in the background:
    1. Takes a **snapshot** of the primary's EBS volumes
    2. Creates standby volumes from the snapshot (initializes in background)
    3. Enables **synchronous block-level replication** between primary and standby
- Can apply immediately or schedule for the next maintenance window
- **Performance impact**: write-sensitive workloads may see increased I/O latency during and after conversion due to synchronous replication overhead
- Best practice for production: instead of direct conversion —
    1. Create a **read replica**
    2. Enable backups on the replica
    3. Convert the replica to Multi-AZ
    4. Promote it to primary
- Supported via Console (`Convert to Multi-AZ`), CLI (`modify-db-instance --multi-az`), or API (`ModifyDBInstance MultiAZ=true`)
- Completion fires event **RDS-EVENT-0025**

## RDS & Aurora Security

**Encryption at rest**
- Uses **AWS KMS** (AES-256); enabled at DB creation time — **cannot be enabled on a running unencrypted instance**
- Encrypts: DB storage, automated backups, read replicas, snapshots
- To encrypt an existing unencrypted DB: take a snapshot → copy snapshot with encryption enabled → restore from encrypted snapshot

**Encryption in transit**
- **SSL/TLS** for all engines (Db2, MySQL, MariaDB, PostgreSQL, Oracle, SQL Server)
- Can connect to RDS Proxy via TLS 1.3 even if the underlying instance only supports an older TLS version
- RDS Proxy certs come from **AWS Certificate Manager (ACM)** — no manual cert download needed

**Network**
- Deploy DB instances in a **VPC** (private subnets) — no public internet access by default
- Access controlled by **Security Groups** (IP ranges or EC2 instances)
- Use **AWS PrivateLink** (VPC Interface Endpoints) for private API calls without internet routing

**Identity & Access Management**
- **IAM policies** control who can manage RDS resources (create, modify, delete instances, tags, security groups)
- **IAM database authentication** — authenticate to the DB using an IAM-generated auth token instead of a password; token valid **15 minutes**; no password transmitted over network; supported for **MySQL** and **PostgreSQL**
- **Kerberos / Microsoft Active Directory** — external authentication for SQL Server, MySQL, Oracle, PostgreSQL, Db2 (not MariaDB); enables SSO + centralized credential management

**Authentication methods summary**

| Method | Description | Supported engines |
| ------ | ----------- | ----------------- |
| **Password** | DB-native user/password | All |
| **IAM DB auth** | IAM-generated token (15 min TTL) | MySQL, PostgreSQL |
| **Kerberos** | Active Directory / Kerberos tickets | SQL Server, MySQL, Oracle, PostgreSQL, Db2 |

**Secrets Manager**
- Integrate with **AWS Secrets Manager** to manage, rotate, and retrieve DB credentials automatically
- Avoids hardcoded passwords in app code

**Shared responsibility**
- AWS: infrastructure, patching, backups, replication security
- Customer: query tuning, network/security group config, IAM policies, encryption choice, in-DB user management

## RDS Proxy

- Fully managed **database connection proxy** between app and RDS/Aurora
- Sits between application and DB; understands the DB protocol
- **Serverless**, highly available, deployed across **multiple AZs**; compute independent of the DB instance

**Connection pooling & multiplexing**
- Maintains a **connection pool** — reuses existing DB connections across app requests
- Default reuse granularity: **per transaction** (multiplexing); per statement when `autocommit=ON`
- Reduces DB memory/CPU overhead from opening/closing many connections
- Prevents "**too many connections**" errors by capping DB-level connections while serving more app connections
- When pool is full: queues/throttles requests (latency may increase); sheds load if limits exceeded

**Failover resilience**
- On DB failover, RDS Proxy **preserves existing app connections** and routes to the new primary automatically
- Eliminates DNS propagation delay / local DNS caching issues during failover
- Reduces failover time vs direct DB connection (can cut it by up to **66%** for Aurora Multi-AZ)
- Queues incoming requests while the new writer is being promoted

**Security**
- Enforces **IAM authentication** for client → proxy connections even if the DB uses password auth
- Supports **standard IAM auth** (proxy → DB via Secrets Manager creds) and **end-to-end IAM auth** (no Secrets Manager needed; IAM from client to DB)
- Always stores DB credentials in **AWS Secrets Manager**
- TLS between client and proxy (supports TLS 1.0–1.3); can enforce `Require TLS`

**Key constraints**
- Proxy must be in the **same VPC** as the DB; **cannot be publicly accessible**
- One proxy → one target DB instance (multiple proxies can target the same instance)
- Default quota: **20 proxies per account** (can be increased)
- **Pinning** — proxy falls back to per-session connection (no multiplexing) when it detects session state changes that make connection reuse unsafe; minimise pinning for best performance
- Not supported: RDS Custom for SQL Server, VPCs with dedicated tenancy, public proxy endpoints

**Supported engines:** MySQL, MariaDB, PostgreSQL, SQL Server (check Region/version matrix for specifics)

**Use when:**
- App has many short-lived connections (Lambda functions, microservices)
- Protecting DB from connection surges
- Wanting transparent failover for applications
- Enforcing IAM auth without changing DB engine config

## References

- [Amazon RDS User Guide — What is Amazon RDS?](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Welcome.html)
- [Managing capacity automatically with Amazon RDS storage autoscaling](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_PIOPS.Autoscaling.html)
- [Choosing between Amazon EC2 and Amazon RDS — AWS Prescriptive Guidance](https://docs.aws.amazon.com/prescriptive-guidance/latest/migration-sql-server/comparison.html)
- [Fully Managed Relational Database — Amazon RDS](https://aws.amazon.com/rds/)
- [Working with DB instance read replicas](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html)
- [Multi-AZ DB instance deployments for Amazon RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZSingleStandby.html)
- [Converting a DB instance to a Multi-AZ deployment](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.MultiAZ.Migrating.html)
- [Security in Amazon RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.html)
- [Database authentication with Amazon RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/database-authentication.html)
- [Amazon RDS Proxy](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-proxy.html)
- [RDS Proxy concepts and terminology](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-proxy.howitworks.html)

