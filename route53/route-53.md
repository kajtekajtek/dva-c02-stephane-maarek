# Amazon Route 53

## DNS

### What is DNS?

- **Domain Name System (DNS)**: hierarchical, decentralized naming system for internet-connected resources
- Translates human-friendly domain names (e.g. `example.com`) into computer-friendly IP addresses
- Eliminates need to memorize IP addresses; browsers use domain names, DNS resolves to IPs
- Two IP formats: **IPv4** (e.g. `192.0.2.44`) and **IPv6** (e.g. `2001:0db8:85a3:0000:0000:abcd:0001:2345`)

### DNS Terminologies

| Term | Definition |
|---|---|
| **Domain Name** | Human-friendly name associated with an internet resource (e.g. `google.com`) |
| **IP Address** | Unique numeric network address; IPv4 = 4 dot-separated octets, IPv6 = colon-separated hex |
| **TLD (Top-Level Domain)** | Rightmost part of a domain (e.g. `com`, `org`, `net`); managed by ICANN-delegated parties |
| **SLD (Second-Level Domain)** | The part immediately left of the TLD (e.g. `google` in `google.com`) |
| **Subdomain** | Subdivision of a domain (e.g. `history` in `history.school.edu`) |
| **FQDN (Fully Qualified Domain Name)** | Absolute domain name incl. all parent domains up to root; ends with `.` (e.g. `mail.google.com.`) |
| **Name Server** | Server that translates domain names to IP addresses; can be authoritative or recursive |
| **Authoritative Name Server** | Gives definitive answers for domains it controls |
| **DNS Resolver / Recursive Resolver** | Intermediary server (usually ISP-provided) that queries other name servers on behalf of clients; caches results |
| **Root Server** | Top of DNS hierarchy; 13 logical root servers (each anycast-mirrored); direct queries to TLD servers |
| **TLD Server** | Handles queries for a specific TLD; returns authoritative name server for the requested domain |
| **Zone File** | Text file on a name server mapping domain names to IP addresses and other records |
| **Record** | Single mapping within a zone file (e.g. domain → IP, domain → mail server) |
| **TTL (Time To Live)** | Duration (in seconds) a DNS resolver caches a record before re-querying |
| **Zone Apex** | The root/naked domain itself (e.g. `example.com`), without any subdomain prefix; also called root domain or naked domain |

### How DNS Works

Step-by-step resolution of `www.example.com`:

1. User enters `www.example.com` in browser
2. Browser checks local cache and `hosts` file; if not found, queries the **DNS resolver** (ISP or configured resolver e.g. `8.8.8.8`)
3. Resolver queries a **Root Name Server** → root server returns address of `.com` TLD name server
4. Resolver queries the **.com TLD Name Server** → returns the authoritative name servers for `example.com`
5. Resolver caches those name servers (typically ~2 days)
6. Resolver queries an **Authoritative Name Server** for `example.com` → returns IP address (e.g. `192.0.2.44`) for `www.example.com`
7. Resolver returns IP to browser (caches it per record TTL)
8. Browser sends HTTP request to `192.0.2.44` → web server returns page

## Amazon Route 53

### What is Route 53?

- Highly available and scalable **cloud DNS service** by AWS
- Name "Route 53" references TCP/UDP port **53** (standard DNS port)
- Three main capabilities:
    - **Domain Registration**: purchase and manage domain names directly through Route 53
    - **DNS Service**: authoritative DNS; routes traffic by translating domain names to IPs
    - **Health Checking**: monitors health/performance of resources; enables DNS failover
- Integrates natively with AWS resources (EC2, ELB, CloudFront, S3, API Gateway)
- **100% SLA** availability guarantee (only AWS service with this)
- Supports multiple **routing policies**: Simple, Weighted, Latency-based, Geolocation, Geoproximity, Failover, IP-based, Multivalue Answer

### Records

A **DNS record** in Route 53 defines how traffic is routed for a domain/subdomain. Each record has:

- **Name**: domain or subdomain (e.g. `www.example.com`)
- **Type**: record type (A, AAAA, CNAME, etc.)
- **Value**: data the record points to (IP, hostname, etc.)
- **TTL**: how long resolvers cache the record
- **Routing Policy** – how Route 53 responds to queries

#### TTL (Time To Live)

- Duration (in seconds) a DNS resolver caches a record before re-querying the authoritative name server
- While cached, all DNS queries are answered locally by the resolver — no round-trip to Route 53
- **High TTL** (e.g. 86400s = 24h): less DNS traffic, lower cost, but changes propagate slowly
- **Low TTL** (e.g. 60s): changes propagate quickly, but more DNS queries = higher cost
- Recommendation: lower TTL before planned record changes, raise it back after
- **Alias records**: TTL is managed by AWS, cannot be set manually
- TTL is mandatory for all non-alias records

#### Record Types

| Type | Full Name | Description |
|---|---|---|
| **A** | Address | Maps domain/subdomain to an **IPv4** address |
| **AAAA** | IPv6 Address | Maps domain/subdomain to an **IPv6** address |
| **CNAME** | Canonical Name | Maps a name to another domain name; **cannot** be used at zone apex (root domain) |
| **MX** | Mail Exchange | Routes email to mail servers; includes priority values |
| **NS** | Name Server | Specifies authoritative name servers for the hosted zone |
| **SOA** | Start of Authority | Stores admin info about the zone (primary NS, email, serial, TTL defaults) |
| **TXT** | Text | Arbitrary text; used for SPF, DKIM, domain ownership verification |
| **CAA** | Certification Authority Authorization | Specifies which CAs can issue SSL/TLS certs for the domain |
| **SRV** | Service Locator | Specifies hostname and port of servers for specific services |
| **PTR** | Pointer | Reverse DNS lookup; maps IP to domain name |

#### Alias Records (Route 53-specific extension)

- Map domain to **AWS resources**:
    - Elastic Load Balancers
    - CloudFront Distributions
    - API Gateway
    - Elastic Beanstalk environments
    - S3 Websites
    - VPC Interface Endpoints
    - Global Accelerator accelerator
    - Route 53 record in the same hosted zone
    - **You cannot set an ALIAS record for an EC2 DNS name**
- **Can** be used at the zone apex (unlike CNAME)
- Auto-update when underlying AWS resource's IP changes
- No charge for alias record DNS queries
- Cannot set custom TTL (AWS manages it)
- Always of type A/AAAA

#### CNAME vs Alias

| Feature | CNAME | Alias |
|---|---|---|
| Points to | Any hostname (e.g. `app.other.com`) | AWS resource only (ELB, CloudFront, S3, etc.) |
| Zone apex support | No | Yes |
| DNS query charge | Yes - $0.40/million queries (first 1B), $0.20/million after | No - free |
| TTL | Configurable | Managed by AWS |
| Works for non-AWS targets | Yes | No |
| DNS standard | RFC-compliant | Route 53 proprietary extension |
| Returned in DNS response | The target hostname (requires 2nd lookup) | The resolved IP directly |

- Prefer **Alias** whenever the target is an AWS resource — faster, free, and works at zone apex
- Use **CNAME** when pointing to non-AWS hostnames or cross-account resources

### Hosted Zones

A **hosted zone** is a container for DNS records that defines how traffic is routed for a domain and its subdomains.

- Created automatically when registering a domain through Route 53
- Can also be created manually for domains registered elsewhere
- Cost: **$0.50/month** per hosted zone

#### Public vs. Private Hosted Zones

| Feature | Public Hosted Zone | Private Hosted Zone |
|---|---|---|
| Traffic scope | Internet | Within one or more Amazon VPCs |
| Queryable by | Anyone on the internet | Only resources within associated VPCs |
| Use case | Route users to public-facing resources (websites, APIs) | Route traffic internally (microservices, internal tooling) |
| VPC association required | No | Yes (one or more VPCs) |
| VPC settings required | N/A | `enableDnsHostnames` and `enableDnsSupport` must be `true` |
| Supports split-view DNS | N/A | Yes (same domain name as public zone for split-horizon DNS) |
| Conversion | Cannot convert to private | Cannot convert to public |

**Split-View (Split-Horizon) DNS**: create both a public and private hosted zone with the same name; internal clients receive different DNS responses than external internet clients.

## 3rd Party Domains & Route 53

### Domain Registrar vs. DNS Service

- You buy or register your domain name with a Domain Registrar typically by paying annual charges (e.g., GoDaddy, Amazon Registrar Inc., …)
- The Domain Registrar usually provides you with a DNS service to manage your DNS records
- But you can use another DNS service to manage your DNS records
- Example: purchase the domain from GoDaddy and use Route 53 to manage your DNS records

### 3rd Party Registrar with Amazon Route 53

If you buy your domain on a 3rd party registrar, you can still use Route 53 as the DNS Service provider

1. Create a Hosted Zone in Route 53
2. Update NS Records on 3rd party website to use Route 53 Name Servers

- Domain Registrar != DNS Service
- But every Domain Registrar usually comes with some DNS features

## References

- [How internet traffic is routed to your website - Amazon Route 53 docs][1]
- [Working with hosted zones - Amazon Route 53 docs][2]
- [Working with records - Amazon Route 53 docs][3]
- [Supported DNS record types - Amazon Route 53 docs][4]
- [Working with private hosted zones - Amazon Route 53 docs][5]
- [An Introduction to DNS Terminology, Components, and Concepts - DigitalOcean][6]
- [Amazon Route 53 features - AWS][7]
- [Choosing a routing policy - Amazon Route 53 docs][8]

[1]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/welcome-dns-service.html
[2]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zones-working-with.html
[3]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/rrsets-working-with.html
[4]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/ResourceRecordTypes.html
[5]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zones-private.html
[6]: https://digitalocean.com/community/tutorials/an-introduction-to-dns-terminology-components-and-concepts
[7]: https://aws.amazon.com/route53/features/
[8]: https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-policy.html
