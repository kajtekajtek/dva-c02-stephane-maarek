# Security Groups

## Introduction to Security Groups

- Fundamental of network security in AWS
- Act as a firewall on EC2 Instances
- Control EC2 Instance **inbound & outbound traffic**
- Only contain **allow rules**
- Rules can reference **by IP** or **by other security groups**
- Security Groups regulate:
  - Access to Ports
  - Authorised IP ranges – IPv4 and IPv6
  - Control of inbound traffic
  - Control of outbound traffic


| Type            | Protocol | Port Range | Source            | Description    |
| --------------- | -------- | ---------- | ----------------- | -------------- |
| HTTP            | TCP      | 80         | 0.0.0.0/0         | test http page |
| SSH             | TCP      | 22         | 122.149.196.85/32 |                |
| Custom TCP Rule | TCP      | 4567       | 0.0.0.0/0         | java app       |

## Security Groups - Good to Know

- Can be attached to multiple instances
- Instance can have multiple security groups
- Locked down to a region/VPC combination
- Lives "outside" of instance - if traffic is blocked, the instance won't see it
- It's a good practice to maintain one separate security group for SSH access
- If the application:
  - is not accessible due to a **time out**, then it is a **security group issue**
  - throws a **"connection refused"** error, then the traffic went through and it is the **application error**
- By default:
  - All inbound traffic is **blocked**
  - All outbound traffic is **authorised**

## Referencing Security Groups

- `Instance A` has `Security Group 1` attached which authorize inbound traffic from `Security Group 1` & `Security Group 2`
- Other instances with `Security Group 1` or `Security Group 2` can connect to `Instance A`
- `Instance B` which has only `Security Group 3` attached can not send traffic to `Instance A`

## Classic Ports

- **22** - SSH
- **21** - FTP
- **22** - SFTP (Secure FTP)
- **80** - HTTP
- **443** - HTTPS
- **3389** - RDP (Remote Desktop Protocol) - for remote control of instances running Windows
