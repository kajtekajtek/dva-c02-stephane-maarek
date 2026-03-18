# Auto Scaling Group

## What’s an Auto Scaling Group?

- The goal of an Auto Scaling Group (ASG) is to automatically:
    - **Scale out** (add EC2 instances) to match an increased load
    - **Scale in** (remove EC2 instances) to match a decreased load
    - Ensure a minimum and a maximum amount of EC2 instances running
    - Register new instances to a load balancer
    - Re-create an EC2 instance in case any of them is terminated (ex: if unhealthy)
- **It is free** (you only pay for the underlying EC2 instances)

## Auto Scaling Group Attributes

- A Launch Template (“Launch Configurations”)
    - AMI + Instance Type
    - EC2 User Data
    - EBS Volumes
    - Security Groups
    - SSH Key Pair
    - IAM Roles for your EC2 Instances
    - Network + Subnets Information
    - Load Balancer Information
- Min Size / Max Size / Initial Capacity
- Scaling Policies

## CloudWatch Alarms & Scaling

- It is possible to scale an ASG based on CloudWatch alarms
- An alarm monitors a metric (such as Average CPU, or a custom metric)
- Metrics such as Average CPU are computed for the ASG's every instance
- Based on the alarm:
    - We can create scale-out policies (increase the number of instances)
    - We can create scale-in policies (decrease the number of instances)

##  Scaling Policies

### Dynamic Scaling

#### Target Tracking Scaling

    - Scaling based on defined target value
    - Example: scale to keep average ASG CPU usage at ~40%

#### Simple / Step Scaling

    - Scaling based on CloudWatch alarms
    - When CPU usage > 70%, then add 2 units
    - When CPU usage < 30%, then remove 1

### Scheduled Scaling

- Scaling based on pre defined patterns
- Example: increase the min capacity to 10 at 5 pm on Fridays

### Predictive scaling 

- Scaling based on load forecast
- continuously forecast load and schedule scaling ahead

## Good metrics to scale by

- CPUUtilization: Average CPU utilization across your instances
- RequestCountPerTarget: to make sure the number of requests per EC2 instances is stable
- Average Network In / Out (if you’re application is network bound)
- Any custom metric

## Scaling Cooldowns

- After a scaling activity happens, you are in the cooldown period (default 300 seconds)
- During the cooldown period, the ASG will not launch or terminate additional instances (to allow for metrics to stabilize)
- Advice: Use a ready-to-use AMI to reduce configuration time in order to be serving request fasters and reduce the cooldown period

## Instance Refresh

- Update the instances in your Auto Scaling group. 
- Useful when a configuration change requires you to replace instances or their root volumes
- MinHealthyPercentage: the percentage of the desired capacity to keep in service during an instance refresh so that the refresh can continue
- Instance warmup: time period from when a new instance's state changes to InService to when it is considered to have finished initializing