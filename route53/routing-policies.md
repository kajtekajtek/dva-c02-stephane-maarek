# Routing Policies

## Route 53 Routing Policies

When you create a record, you choose a **routing policy**. It determines how Route 53 responds to DNS queries for that record [1].

**All policies (overview)** [1]:


| Policy                | Use case                                                             |
| --------------------- | -------------------------------------------------------------------- |
| **Simple**            | Single resource for a function; standard DNS, no special routing     |
| **Failover**          | Active-passive failover                                              |
| **Geolocation**       | Route by user location                                               |
| **Geoproximity**      | Route by resource location; optional traffic shift between locations |
| **Latency**           | Resources in multiple AWS Regions; route to lowest-latency Region  |
| **IP-based**          | Route by user location when you have source IP ranges              |
| **Multivalue answer** | Up to eight healthy records, chosen at random                        |
| **Weighted**          | Split traffic across resources in proportions you set                |


Private hosted zones: Simple, Failover, Geolocation, Geoproximity, Latency, Multivalue, and Weighted are supported [1].

### Routing Policies - Simple

- Standard DNS records; **no** weighted, latency, or other special Route 53 routing [2]
- Typical use: route traffic to **one** resource (e.g. web server) [2]
- **Console constraint**: cannot create **multiple** records with the **same name and type**; you **can** put **multiple values in one record** (e.g. several IPs) [2]
- **Multiple values in one record**: Route 53 returns **all** values to the recursive resolver in **random order**; resolver passes them to the client; client picks one and may resubmit [2]
- **Simple alias**: only **one** AWS resource or one record in the current hosted zone [2]
- Multiple IPs in simple routing: **not** health-checked [2]

### Routing Policies - Weighted

- Associate **multiple** resources with one domain or subdomain; control **how much** traffic each gets [3]
- Uses: load balancing, canary / testing new software versions [3]
- **Setup**: same **name** and **type** per resource; each record gets a **relative weight** [3]
- **Traffic share**: `weight for record / sum of weights for all records in the group` [3]
- **Example**: weights **1** and **255** → 1/256 and 255/256 of traffic [3]
- Adjust balance by changing weights; set a record’s weight to **0** to stop sending traffic to that resource [3]
- **Private hosted zones**: supported [3]
- **Health checks** (when all records in the group have health checks, mix of nonzero and zero weights) [3]:
  - Route 53 considers **nonzero-weight** records first
  - If **all** nonzero-weight records are unhealthy, Route 53 considers **zero-weight** records

### Routing Policies – Latency-based

- App in **multiple AWS Regions**: send users to the Region with **lowest latency** [4]
- **Create** a **latency record** per resource per Region; Route 53 picks the Region with best latency for the querier and returns that record’s value (e.g. IP) [4]
- **Example** [4]: ELB in `us-west-2` and `ap-southeast-1`; user in London → Route 53 compares London→Oregon vs London→Singapore latency and returns the better Region’s ELB IP
- Latency data reflects **user ↔ AWS** only; if resources are **not** in AWS, real latency can differ a lot [4]
- Latency **changes over time** (routing, connectivity); measurements are over time; same user may get different Regions on different days [4]
- **EDNS0 / edns-client-subnet**: if the resolver sends a truncated client IP, Route 53 can use it for routing [4]
- **Private hosted zones**: supported [4]

### Geolocation

- Route traffic by **geographic location of DNS queries** (where queries originate), not by latency [5]
- Example: route all Europe queries to an ELB in **eu-central-1** [5]
- Uses: localize content / language, **restrict** distribution to licensed regions, predictable per-location routing to same endpoint [5]
- **Granularity**: continent, country, or **US state** [5]
- **Overlapping regions** (e.g. North America + Canada): **smallest** geographic region wins [5]
- **IP-to-location mapping**: some IPs have no geo mapping; create a **default** record for unmapped IPs and locations you did not define; else **no answer** [5]
- **Public and private** hosted zones [5]
- **EDNS0**: resolvers can send client subnet info [9]

### Geoproximity

- Route by **user location** and **resource location**; send to **closest available** resource [6]
- Optional **bias** (integer): expands or shrinks the geo area from which traffic is routed to a resource [6]
- **Per rule**, specify resource position:
  - **AWS**: AWS Region or **Local Zone Group** where the resource lives [6]
  - **Non-AWS**: **latitude and longitude** [6]
- **Bias** [6]:
  - **+1 to +99**: larger area for that resource; adjacent regions shrink
  - **-1 to -99**: smaller area for that resource; adjacent regions expand
- **Formula** (biased distance): `Biased distance = actual distance * [1 - (bias/100)]` [6]
  - Positive bias: treats query source and resource as **closer** than they are (example in docs: bias +50 halves distance for comparison) [6]
- **Traffic Flow**: maps illustrating bias; bias changes in **small increments** recommended (border users can swing traffic sharply) [6]

### Failover (Active-Passive)

- **Failover routing policy** [7]: send traffic to a resource when it is **healthy**, else to a **different** resource when the first is unhealthy
- Primary and secondary records can target anything from an **S3 website bucket** to a **complex tree of records** [7]
- **Private hosted zones**: supported [7]

**Active-active vs active-passive** [8]:

| Mode | How |
|---|---|
| **Active-active** | Use any routing policy **except** failover (or combine policies); all same-name/type/policy records are active unless unhealthy; Route 53 can return any **healthy** record [8] |
| **Active-passive** | Use **failover** routing policy; primary serves most of the time, secondary **standby** if **all** primary targets are down [8] |

**Active-passive behavior** [8]:

- Answers include **only healthy primary** records while any primary is healthy
- If **all** primary resources are unhealthy, answers use **only healthy secondary** records

**One primary + one secondary**: create two failover records (Primary / Secondary); healthy primary wins [8]

**Multiple resources per failover side** [8]:

- Primary failover record is healthy if **at least one** associated resource is healthy [10]
- Non-alias targets: **health check** per resource; alias-eligible AWS targets: **Evaluate Target Health = Yes** on alias records (do **not** attach a separate health check to those alias targets) [8]

**Common pattern** [8]: primary = web server, secondary = **S3 static website** with a short “temporarily unavailable” page (secondary can be a single failover **alias** to the bucket endpoint)

**Weighted + active-passive caveat** [8]: nonzero weights preferred; only if **all** nonzero-weight records are unhealthy does Route 53 use **zero-weight** records; last healthy server may be overloaded

### IP Based

- Fine-tune DNS routing using **your** mappings of **client IP ranges to endpoints** (uploaded data), not only Route 53’s built-in geo/latency data [11]
- Use cases [11]:
  - Send users from certain **ISPs** to specific endpoints (cost or performance)
  - **Override** geolocation (and similar) when you know client locations better than default data
- **CIDR** [11]:
  - IPv4: prefix length **1–24**
  - IPv6: prefix length **1–48**
  - Default for `0.0.0.0/0` or `::/0`: use location **`*`**
- **Longest-prefix behavior**: query source CIDR **longer** than a stored block still matches the **shorter** stored block (example in docs: `2001:0DB8::/32` matches a query from `2001:0DB8:0000:1234::/48`); reverse (query shorter than stored /48) does **not** match, falls through to default [11]
- **Model** [11]:
  - **CIDR block**: one range in CIDR notation
  - **CIDR location**: named list of blocks (IPv4 and/or IPv6); name is often descriptive but can be any string
  - **CIDR collection**: named group of locations; all RRsets with same name/type using IP-based routing must reference the **same** collection
- **Private hosted zones**: **not** supported [11]

### Multi value

- Return **multiple** values (e.g. web server IPs) per query; optional **health check** per value so only **healthy** targets are returned [12]
- **Not** a replacement for a **load balancer**; improves availability and spreads load via DNS [12]
- One **multivalue answer** record per resource; optional health check on each [12]
- Responses [12]:
  - Up to **eight healthy** records; answers can differ per resolver (approx. random)
  - With health check: IP included only when that check is **healthy**
  - Without health check: record always treated as **healthy**
  - **≤8 healthy** records: response includes **all** healthy records
  - **All** unhealthy: responds with up to **eight unhealthy** records
- Clients may retry another IP from the set if one fails after cache [12]
- **Private hosted zones**: supported [12]

## References

- [Choosing a routing policy - Amazon Route 53][1]
- [Simple routing - Amazon Route 53][2]
- [Weighted routing - Amazon Route 53][3]
- [Latency-based routing - Amazon Route 53][4]
- [Geolocation routing - Amazon Route 53][5]
- [Geoproximity routing - Amazon Route 53][6]
- [Failover routing - Amazon Route 53][7]
- [Active-active and active-passive failover - Amazon Route 53][8]
- [How Amazon Route 53 uses EDNS0 to estimate the location of a user][9]
- [How Amazon Route 53 chooses records when health checking is configured][10]
- [IP-based routing - Amazon Route 53][11]
- [Multivalue answer routing - Amazon Route 53][12]

[1]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-policy.html
[2]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-policy-simple.html
[3]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-policy-weighted.html
[4]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-policy-latency.html
[5]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-policy-geo.html
[6]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-policy-geoproximity.html
[7]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-policy-failover.html
[8]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-failover-types.html
[9]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-policy-edns0.html
[10]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-how-route-53-chooses-records.html
[11]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-policy-ipbased.html
[12]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-policy-multivalue.html
