# Scalability & High Availability

## Scalability

- Scalability means that system can handle greater loads by adapting

### Vertical Scalability

Vertically scalability means increasing capacity of a node in the infrastructure
- Common for non distributed systems
- RDS, ElastiCache are services that can scale vertically.
- There’s usually a limit to how much you can vertically scale (hardware limit)

### Horizontal Scalability

Horizontal Scalability means increasing the number of nodes in the infrastructure
- Horizontal scaling implies distributed systems
- Common for web applications / modern applications
- It’s easier to horizontally scale thanks the cloud services such as Amazon EC2

## High Availability

High availability means running the application in multiple data centers (in AWS: Availability Zones)
- The goal of high availability is to survive a data center loss
- The high availability can be passive (e.g. for RDS Multi AZ)
- The high availability can be active (for horizontal scaling)

## High Availability & Scalability For EC2

- Vertical Scaling: Increase instance size (= scale up / down)
    - From: t2.nano - 0.5G of RAM, 1 vCPU
    - To: u-12tb1.metal – 12.3 TB of RAM, 448 vCPUs
- Horizontal Scaling: Increase number of instances (= scale out / in)
    - Auto Scaling Group
    - Load Balancer
- High Availability: Run instances for the same application across multi AZ
    - Auto Scaling Group multi AZ
    - Load Balancer multi AZ