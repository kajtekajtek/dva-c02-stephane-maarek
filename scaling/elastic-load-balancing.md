# Elastic Load Balancing

## What is load balancing?

- Load Balances are servers that forward traffic to multiple servers (e.g., EC2 instances) downstream

## Why use a load balancer?

- **Spreading load** across multiple downstream instances
- **Exposing a single point of access** (DNS) to your application
- **Seamlessly handling failures** of downstream instances
- Doing **regular health checks** to your instances
- Providing SSL termination (HTTPS) for your websites
- Enforcing stickiness with cookies
- **High availability** across zones
- **Separating public traffic** from private traffic

## Elastic Load Balancer (ELB)

- The Elastic Load Balancer is a **managed load balancer**
- AWS manages upgrades, maintenance and high availability
- AWS provides only a few configuration options
- It is integrated with many AWS offerings / services
    - EC2, EC2 Auto Scaling Groups, Amazon ECS
    - AWS Certificate Manager (ACM), CloudWatch
    - Route 53, AWS WAF, AWS Global Accelerator

### Health Checks

- Crucial for Load Balancing
- Enable the load balancer to know if instances it forwards traffic to are available
- The health check is done on a port and a route (/health is common)
- If the response is not 200 (OK), then the instance is considered unhealthy

### Types of load balancer on AWS

AWS has 4 kinds of managed Load Balancers
- **Classic Load Balancer** (v1 - old generation) – 2009 – CLB
    - HTTP, HTTPS, TCP, SSL (secure TCP)
- **Application Load Balancer** (v2 - new generation) – 2016 – ALB
    - HTTP, HTTPS, WebSocket
- **Network Load Balancer** (v2 - new generation) – 2017 – NLB
    - TCP, TLS (secure TCP), UDP
- **Gateway Load Balancer** – 2020 – GWLB
    - Operates at layer 3 (Network layer) – IP Protocol
- Overall, it is recommended to use the newer generation load balancers as they provide more features
- Some load balancers can be setup as internal (private) or external (public) ELBs

### Load Balancer Security Groups

- Load Balancer Security Group
    - Users can access load balancer from anywhere using HTTP or HTTPS. 
    - Port Range: 80 or 443 
    - Source: 0.0.0.0/0 
- Application Security Group
    - EC2 instances should only allow traffic coming directly from the load balancer
    - Port range: 80 
    - Source: **Load Balancer Security Group**
- EC2 instance is only allowing traffic originating from the load balancer, which provides an enhanced security mechanism. 

