# AMI

## AMI Overview

- An **Amazon Machine Image (AMI)** is an image that provides the software that is required to set up and boot an Amazon EC2 instance. 
- Each AMI also contains a block device mapping (e.g. EBS Snapshot) that specifies the block devices to attach to the instances that you launch. 
- AMI provides **faster boot / configuration times** because software is pre-packaged
- You must specify an AMI when you launch an instance. 
- The AMI must be compatible with the instance type that you chose for your instance. 
- You can use an AMI **provided by AWS**, a **public AMI**, an AMI **shared** with you, or an AMI that you **purchased from the AWS Marketplace**.
- An AMI is specific to the following:
    - Region (can be copied across regions)
    - Operating system
    - Processor architecture
    - Root volume type
    - Virtualization type
- You can launch multiple instances from a single AMI when you require multiple instances with the same configuration. 
- You can use different AMIs to launch instances when you require instances with different configurations

## AMI Process from an EC2 Instance

- Start an EC2 instance and customize it
- Stop the instance (for data integrity)
- Build an AMI – this will also create EBS snapshots
- Launch instances from other AMIs
