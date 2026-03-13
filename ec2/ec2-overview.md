# Amazon EC2

- **Elastic Compute Cloud (EC2)** is a part of AWS that allows users to rent virtual computers on which to run their own applications. 
- It's a way to do Infrastructure as a Service on AWS
- It's features consist of:
    - Renting virtual machines (**EC2 instances**)
    - Storing data on virtual drives (**EBS volumes**)
    - Distributing volume across machines using **ELB - Elastic Loud Balancer**
    - Scaling services using an auto-scaling group (**ASG**)

## EC2 sizing & configuration options

- OS
    - Linux, Windows, Mac OS
- CPU
- RAM
- Storage space
    - Network-attached (EBS & EFS)
    - Hardware-attached (EC2 Instance Store)
- Network card
    - speed of the card, public IP address
- Firewall rules

## EC2 User Data

- A script to bootstrap instances
- Run once at the instance's first start
- Used to automate:
    - installing updates and software
    - downloading files from the internet
    - ...
- Runs with the root user

## EC2 Instance Types

Different types of EC2 instances optimised for different use cases 
- https://aws.amazon.com/ec2/instance-types/

### Naming Convention

`m5.2xlarge`
- **m**: instance class
- **5**: generation
- **2xlarge**: size within the instance class

### General Purpose

- Balanced between compute, memory and networking.
- `t3.micro` used throughout the course is a general purpose EC2 instance

### Compute Optimized

Optimized for compute intensive tasks (CPU bound)
- Batch processing workloads
- High performance web servers
- Media transcoding
- High performance web servers
- High performance computing (HPC)
- Scientific modeling & machine learning
- Dedicated gaming servers

### Memory Optimized

Optimized for workloads that process large data sets in memory
- High performance, relational/non-relational databases
- Distributed web scale cache stores
- In-memory databases optimized for BI (business intelligence)
- Applications performing real-time processing of big unstructured data

### Storage Optimized

Optimized for storage-intensive tasks that require high, sequential read and write access to large data sets on local storage
- High frequency online transaction processing (OLTP) systems
- Relational & NoSQL databases
- Cache for in-memory databases (for example, Redis)
- Data warehousing applications
- Distributed file systems

### Accelerated Computing

Use hardware accelerators, or co-processors, to perform functions more efficiently. 
- Floating point number calculations,
- Graphics processing
- Data pattern matching

### HPC Optimized

Optimized to offer the best price performance for running HPC workloads at scale. 
- Large, complex simulations
- Deep learning workloads

### Example

| Instance      | vCPU | Mem (GiB) | Storage              | Network Performance    | EBS Bandwidth (Mbps) |
|---------------|------|-----------|----------------------|-----------------------|----------------------|
| t2.micro      | 1    | 1         | EBS-Only             | Low to Moderate       |                      |
| t2.xlarge     | 4    | 16        | EBS-Only             | Moderate              |                      |
| c5d.4xlarge   | 16   | 32        | 1 x 400 NVMe SSD     | Up to 10 Gbps         | 4,750                |
| r5.16xlarge   | 64   | 512       | EBS Only             | 20 Gbps               | 13,600               |
| m5.8xlarge    | 32   | 128       | EBS Only             | 10 Gbps               | 6,800                |

## EC2 Instance Purchasing Options

- On-Demand Instances – short workload, predictable pricing, pay by second
- Reserved (1 & 3 years)
  - Reserved Instances – long workloads
  - Convertible Reserved Instances – long workloads with flexible instances
- Savings Plans (1 & 3 years) – commitment to an amount of usage, long workload
- Spot Instances – short workloads, cheap, can lose instances (less reliable)
- Dedicated Hosts – book an entire physical server, control instance placement
- Dedicated Instances – no other customers will share your hardware
- Capacity Reservations – reserve capacity in a specific AZ for any duration

### EC2 On Demand

Pay for what you use:
    - **Linux or Windows**: billing per second, after the first minute
    - **Other**: billing per hour

- Has the highest cost but no upfront payment
- No long-term commitment
- Recommended for **short-term** and **un-interrupted workloads**, where you can't predict how the application will behave

### EC2 Reserved Instances

- Up to 72% discount compared to On-demand
- You reserve a specific instance attributes 
  - Instance Type, Region, Tenancy, OS
- Reservation Period 
  – 1 year (+discount) 
  - 3 years (+++discount)
- Payment Options 
  – No Upfront (+)
  - Partial Upfront (++)
  - All Upfront (+++)
- Reserved Instance’s Scope – Regional or Zonal (reserve capacity in an AZ)
- Recommended for **steady-state usage applications**, e.g. database
- You can buy and sell in the **Reserved Instance Marketplace**
- Convertible Reserved Instance
  - Allows change of the EC2 instance type, instance family, OS, scope and tenancy
  - Up to 66% discount

### EC2 Savings Plans

- Get a discount based on long-term usage 
  - up to 72% - same as RIs
- Commit to a certain type of usage 
  - $10/hour for 1 or 3 years
- Usage beyond EC2 Savings Plans is billed at the On-Demand price
- Locked to a specific instance family & AWS region (e.g., M5 in us-east-1)
- Flexible across:
  - Instance Size (e.g., m5.xlarge, m5.2xlarge)
  - OS (e.g., Linux, Windows)
  - Tenancy (Host, Dedicated, Default)

### EC2 Spot Instances

- Can get a discount of **up to 90%** compared to On-demand
- Instances that **you can “lose” at any point of time** if your max price is less than the current spot price
- The MOST cost-efficient instances in AWS
- Useful for **workloads that are resilient to failure**
  - Batch jobs
  - Data analysis
  - Image processing
  - Any distributed workloads
  - Workloads with a flexible start and end time
- **Not suitable for critical jobs or databases**

### EC2 Dedicated Hosts

- A physical server with EC2 instance capacity fully dedicated to your use
- Allows addressing compliance requirements and using existing server-bound software licenses (per-socket, per-core, per-VM software licenses)
- Purchasing Options:
  - On-demand – pay per second for active Dedicated Host
  - Reserved - 1 or 3 years (No Upfront, Partial Upfront, All Upfront)
- The most expensive option
- Useful for software that have complicated licensing model (BYOL – Bring Your Own License)
- Or for companies that have strong regulatory or compliance needs

### EC2 Dedicated Instances

- Instances run on hardware that’s dedicated to you
- May share hardware with other instances in same account
- No control over instance placement (can move hardware after Stop / Start)

### EC2 Capacity Reservations

- Reserve On-Demand instances capacity in a specific AZ for any duration
- You always have access to EC2 capacity when you need it
- No time commitment (create/cancel anytime), no billing discounts
- Combine with Regional Reserved Instances and Savings Plans to benefit from billing discounts
- You’re charged at On-Demand rate whether you run instances or not
- Suitable for short-term, uninterrupted workloads that needs to be in a specific AZ

### Which purchasing option is right for me?

• On demand: coming and staying in resort whenever we like, we pay the full price
• Reserved: like planning ahead and if we plan to stay for a long time, we may get a good discount.
• Savings Plans: pay a certain amount per hour for certain period and stay in any room type (e.g., King, Suite, Sea View, …)
• Spot instances: the hotel allows people to bid for the empty rooms and the highest bidder keeps the rooms. You can get kicked out at any time
• Dedicated Hosts: We book an entire building of the resort
• Capacity Reservations: you book a room for a period with full price even you don’t stay in it

### Price Comparison

- Example: `m4.large` in `us-east-1`

| Price Type                           | Price (per hour)                      |
| ------------------------------------- | ------------------------------------- |
| On-Demand                            | $0.10                                 |
| Spot Instance (Spot Price)           | $0.038 - $0.039 (up to 61% off)       |
| Reserved Instance (1 year)           | $0.062 (No Upfront) - $0.058 (All Upfront) |
| Reserved Instance (3 years)          | $0.043 (No Upfront) - $0.037 (All Upfront) |
| EC2 Savings Plan (1 year)            | $0.062 (No Upfront) - $0.058 (All Upfront) |
| Reserved Convertible Instance (1 year)| $0.071 (No Upfront) - $0.066 (All Upfront) |
| Dedicated Host (On-Demand)           | On-Demand Price                       |
| Dedicated Host Reservation           | Up to 70% off                         |
| Capacity Reservations                | On-Demand Price                       |
