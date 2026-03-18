# Cross-Zone Load Balancing

- With cross-zone load balancing, each load balancer node for your Load Balancer **distributes requests evenly across the registered instances in all enabled Availability Zones.** 
- If cross-zone load balancing is disabled, each load balancer node **distributes requests evenly across the registered instances in its Availability Zone only**.

#### Application Load Balancer

- Enabled by default (can be disabled at the Target Group level)
- No charges for cross-zone data traffic

#### Network Load Balancer & Gateway Load Balancer

- Disabled by default
- You pay charges ($) for cross-zone data traffic if enabled

#### Classic Load Balancer

- Disabled by default
- No charges for cross-zone data traffic if enabled