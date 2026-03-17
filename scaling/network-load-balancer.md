# Network Load Balancer (v2)

- Network load balancers (Layer 4) features:
    - ultra-high performance
    - TLS offloading at scale
    - centralized certificate deployment
    - support for UDP, and static IP addresses for your applications
- Operating at the connection level, Network Load Balancers are **capable of handling millions of requests per second securely** while maintaining ultra-low latencies.
- NLB has **one static IP per AZ**, and supports assigning Elastic IP (helpful for whitelisting specific IP)
- NLB are used for extreme performance, TCP or UDP traffic

## Network Load Balancer – Target Groups

- EC2 instances
- IP Addresses – must be private IPs
- Application Load Balancer
- Health Checks support the TCP, HTTP and HTTPS Protocols