# Application Load Balancer (v2)

- Layer 7 (HTTP)
- Load balancing to **target groups**, e.g. 
    - multiple HTTP applications across machines 
    - multiple applications on the same machine (e.g. containers)
- Support for HTTP/2 and WebSocket
- Support redirects (e.g. from HTTP to HTTPS)
- Great fit for **micro services & container-based applications** (example: Docker & Amazon ECS)
- **Port mapping** feature enables redirect to a dynamic port in ECS

## How Application Load Balancers work

1. Clients make requests to your application.
2. The listeners in your load balancer receive requests matching the protocol and port that you configure.
3. The receiving listener evaluates the incoming request against the rules you specify, and if applicable, routes the request to the appropriate target group.You can use an HTTPS listener to offload the work of TLS encryption and decryption to your load balancer.
4. Healthy targets in one or more target groups receive traffic based on the load balancing algorithm, and the routing rules you specify in the listener.

## Target Groups

- EC2 instances (can be managed by an Auto Scaling Group) – HTTP
- ECS tasks (managed by ECS itself) – HTTP
- Lambda functions – HTTP request is translated into a JSON event
- IP Addresses – must be private IPs
- ALB can route to multiple target groups
- Health checks are at the target group level

## Routing to different target groups

Conditions define the criteria that incoming requests must meet for a listener rule to take effect. If a request matches the conditions for a rule, the request is handled as specified by the rule's actions.

- **Path** conditions 
    - example.com/users 
    - example.com/posts
- **Host** conditions 
    - one.example.com 
    - other.example.com
- **HTTP header** conditions
    - User-Agent: Chrome
    - User-Agent: Safari
- **Query string** conditions
    - example.com/users?id=123&order=false
- **Request method** conditions
- **Source IP** conditions

## Good to Know

- Fixed hostname (XXX.region.elb.amazonaws.com)
- The application servers don’t see the IP of the client directly
- The true IP of the client is inserted in the header X-Forwarded-For
- We can also get Port (X-Forwarded-Port) and proto (X-Forwarded-Proto)
