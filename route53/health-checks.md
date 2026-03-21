# Health Checks

## Route 53 – Health Checks

- **Purpose**: Monitor web servers, email servers, and other resources; optional **CloudWatch** alarms and **SNS** notification when a resource becomes unavailable [1].
- **Each health check** can monitor: 
    - a **specified resource** (e.g. web server)
    - **status of other health checks**
    - an **Amazon CloudWatch alarm** data stream [2].
- Only for **public resources**
- **DNS failover**: Associate a health check with records so Route 53 sends traffic only to healthy resources; unhealthy resources get no traffic for that routing [1], [2].
- **New health checks**: Considered **healthy** until enough data exists for real status (or **unhealthy** if **invert** is enabled) [3], [4].
- **ARC**: **Application Recovery Controller** supports **routing control** health checks with failover records for managed failover (separate from classic health checks) [5], [2].

| Type | Role |
|------|------|
| Endpoint | IP or domain; periodic automated requests; optional user-like requests (e.g. specific URL) [5] |
| Calculated | Aggregates **other** health checks; e.g. alert when count of healthy resources drops below threshold [5] |
| CloudWatch alarm | Monitors same **data stream** as the alarm; not limited to HTTP reachability [5] |

## Monitor an Endpoint

-About 15 global health checkers will check the endpoint health
- **Specify by**: **IP address** (IPv4 or IPv6) or **domain name** (cannot change after create) [6].
- **Protocol**: **HTTP**, **HTTPS**, or **TCP** (protocol fixed after create) [6].
  - **HTTP/HTTPS**: TCP connect, then HTTP(S) request; healthy if **2xx or 3xx** [6].
  - **HTTPS**: Endpoint must support **TLS 1.0, 1.1, or 1.2**; extra pricing vs HTTP [6].
  - **TCP**: Only connection establishment [6].
- **Excluded IPs**: No health checks for **local, private, nonroutable, multicast** ranges (see RFCs linked in AWS docs) [6].
- **EC2**: Recommend **Elastic IP** on the instance so IP does not change; delete health check if instance/EIP removed [6].
- **Non-AWS endpoints**: Additional charge per AWS pricing [6].
- **Domain name mode**: Route 53 resolves name each **request interval**; health checks use **IPv4 only**; need **A** record or **DNS resolution failed** [6].
- **Domain name pitfall**: For failover/geo/latency/multivalue/weighted records, use **per-server** names (e.g. `us-east-2-www.example.com`), **not** the record name (e.g. `www.example.com`), or results are **unpredictable** [6].
- **Path** (HTTP/HTTPS): Any path returning **2xx/3xx** when healthy; optional query string; leading `/` added if omitted [6].
- **Request interval**: **10 s** or **30 s** per checker (immutable after create); **10 s** costs extra; checkers **not synchronized** (burst then quiet possible) [4], [6].
- **Failure threshold**: Consecutive pass/fail count before status flips [6].
- **Aggregation**: Healthy if **> 18%** of checkers report healthy; **≤ 18%** = unhealthy (value may change in future releases) [4].
- **HTTP/HTTPS timing**: TCP within **4 s**; status **2xx/3xx** within **2 s** after connect; **HTTPS does not validate** certificates [4].
- **TCP timing**: Connection within **10 s** [4].
- **String matching** (HTTP/HTTPS): Optional body search in first **5,120 bytes** within **2 s** after status; extra charge [4], [6].
- **Notifications**: Optional CloudWatch alarm on health check; **SNS** to recipients [1].

## Calculated Health Checks

- **Definition**: Parent check monitors **child** endpoint (or other) health checks; implements **minimum quorum** style logic [5], [4].
- **Child limit**: **Up to 256** health checks in “Health checks to monitor” in console [6]
- **Nesting**: **Cannot** monitor other **calculated** health checks [6].
- **Report healthy when** [6]:
  - **At least x of y** healthy (x > y ⇒ always unhealthy; x = 0 ⇒ always healthy)
  - **AND**: all children healthy
  - **OR**: at least one child healthy
- **Disabled child**: Treated as **healthy** unless **invert** used so it counts unhealthy [6].

## Private Hosted Zones

- **Checker location**: Route 53 health checkers are **outside the VPC** [7].
- **Health by IP**: To check an in-VPC endpoint by IP, instance needs a **public IP** [7].
- **Private IP only**: Use **CloudWatch** metric + alarm + health check on alarm **data stream** (e.g. EC2 **StatusCheckFailed**) [7].

## CloudWatch Alarm Health Checks (brief)

- **Data stream**: Route 53 follows alarm **metric data**, not only alarm **state**; improves resiliency (does not wait solely for `ALARM`) [5], [4].
- **Constraints**: Same account; **standard-resolution** metrics; stats **Average, Min, Max, Sum, SampleCount**; no **high-res**, no **M of N** alarms, no **metric math** alarms [5], [6].
- **`SetAlarmState`**: Cannot force health check flip by this API (monitors data stream) [4].

## Further Reading

- [Configuring DNS failover](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-failover-configuring.html)
- [Best practices for Route 53 health checks](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/best-practices-healthchecks.html)
- [Route 53 pricing (health checks)](https://aws.amazon.com/route53/pricing/)

## References

- [How Amazon Route 53 checks the health of your resources][1]
- [Creating Amazon Route 53 health checks][2]
- [Creating and updating health checks][3]
- [How Amazon Route 53 determines whether a health check is healthy][4]
- [Types of Amazon Route 53 health checks][5]
- [Values that you specify when you create or update health checks][6]
- [Configuring failover in a private hosted zone][7]

[1]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/welcome-health-checks.html
[2]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-failover.html
[3]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating.html
[4]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-failover-determining-health-of-endpoints.html
[5]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-types.html
[6]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-creating-values.html
[7]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-failover-private-hosted-zones.html
