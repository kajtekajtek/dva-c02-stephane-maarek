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