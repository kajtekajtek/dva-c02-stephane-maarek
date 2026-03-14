# EBS Volumes

## What’s an EBS Volume?

- An **EBS (Elastic Block Store) Volume** is a network drive you can attach to your instances while they run
- It allows your instances to persist data, even after their termination
- They can only be mounted to one instance at a time (at the Cloud Practitioner certification level)
- Multiple volumes can be attached to one instance
- They are **bound to a specific availability zone**
- EBS Volume is a network drive (i.e. not a physical drive)
    - It uses the network to communicate with the instance, which might cause latency
    - It can be detached from an EC2 instance and attached to another one quickly - useful in case of **failovers**
- To move a volume, you first need to snapshot it
- Provisioned capacity (size in GBs, and IOPS)
    - You get billed for all the provisioned capacity
    - You can increase the capacity of the drive over time

## Delete on Termination attribute

- Controls the EBS volume behaviour on instance termination
- By default **turned on** for the `Root` volume and **turned off** for other volumes
- Set in the AWS console / AWS CLI
- **Exam use case**: turn off to preserve root volume on instance termination

## EBS Snapshots

- Make a backup (snapshot) of your EBS volume at a point in time
- Not necessary to detach volume to do snapshot, but recommended
- Snapshots can be used to move volume's data across AZs & regions
    - Volume `vol-A` created and used in `eu-west-1a`
    - Instance `inst-B` running on `eu-north-1b`
    - Take a snapshot `snapshot-A` of volume `vol-A`
    - Make a copy `snapshot-A-copy` of `snapshot-A` in `eu-north-1` region
    - Recreate a volume `vol-B` from `snapshot-A-copy` snapshot in `eu-north-1b`
    - Attach `vol-B` to `inst-B`

### EBS Snapshots Features

- EBS Snapshot Archive
    - Move a Snapshot to an ”archive tier” that is 75% cheaper
    - Takes within 24 to 72 hours for restoring the archive
- Recycle Bin for EBS Snapshots
    - Setup rules to retain deleted snapshots so you can recover them after an accidental deletion
    - Specify retention (from 1 day to 1 year)
- Fast Snapshot Restore (FSR)
    - Force full initialization of snapshot to have no latency on the first use ($$$)

## EBS Volume Types

- EBS Volumes come in 6 types
    - **gp2 / gp3 (SSD)**: General purpose SSD volume that balances price and performance for a wide variety of workloads
    - **io1 / io2 Block Express (SSD)**: Highest-performance SSD volume for mission-critical low-latency or high-throughput workloads
    - **st1 (HDD)**: Low cost HDD volume designed for frequently accessed, throughput-intensive workloads
    - **sc1 (HDD)**: Lowest cost HDD volume designed for less frequently accessed workloads
- EBS Volumes are characterized in Size | Throughput | IOPS (I/O Ops Per Sec)
- **Only** gp2/gp3 and io1/io2 Block Express can be used as **boot volumes**

## General Purpose Solid State Drive (SSD)

- Cost effective storage, low-latency
- Use cases:
    - Transactional workloads
    - Virtual desktops
    - Medium-sized, single-instance databases
    - Low-latency interactive applications
    - Boot volumes
    - Development and test environments

### gp3:

- **Baseline IOPS performance** of 3,000 IOPS and **throughput** of 125 MiB/s
- Can increase IOPS up to 16,000 and throughput up to 1000 MiB/s independently
- **Size** from 1 GiB to 64 TiB

### gp2:

- **Baseline IOPS performance** scales linearly at a rate of 3 IOPS per GiB of volume size.
    - Baseline IOPS performance scale up to 5,334 GiB in volume size giving a **maximum of 16,000 IOPS** provisioned
- Small gp2 volumes can burst IOPS to 3,000
- **Size** from 1 GiB to 16 TiB

## Provisioned IOPS (PIOPS) SSD

### io2 Block Express (4 GiB – 64 TiB):

- Workloads that require:
    - Consistent sub-millisecond latency with average latency under 500 microseconds 5
    - Sustained IOPS performance
    - More than 80,000 IOPS or 2,000 MiB/s of throughput
- Sub-millisecond latency
- Max PIOPS: 256,000 with an IOPS:GiB ratio of 1,000:1
- Max throughput of 4,000MiB/s
- Supports EBS Multi-attach

### io1 (4 GiB - 16 TiB):

- Use cases:
    - Workloads that require sustained IOPS performance or more than 16,000 IOPS
    - I/O-intensive database workloads
- Max PIOPS: 64,000 for Nitro EC2 instances & 32,000 for other
- Max throughput of 1,000MiB/s
- Can increase PIOPS independently from storage size

### Performance limitations

- There are several factors that can affect the performance of EBS volumes, such as instance configuration, I/O characteristics, and workload demand. **To fully use the IOPS provisioned on an EBS volume, use EBS–optimized instances.**

## Hard Disk Drives (HDD)

- **Cannot be a boot volume**
- 125 GiB to 16 TiB

### Throughput Optimized HDD (st1)

- Big Data, Data Warehouses, Log Processing
- Max throughput 500 MiB/s – max IOPS 500

### Cold HDD (sc1):

- Throughput-oriented storage for data that is infrequently accessed
- Scenarios where the lowest storage cost is important
- Max throughput 250 MiB/s – max IOPS 250
