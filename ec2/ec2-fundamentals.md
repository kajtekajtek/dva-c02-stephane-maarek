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

