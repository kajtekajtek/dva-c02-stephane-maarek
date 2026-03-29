# Amazon CloudFront

## CloudFront Overview

**Amazon CloudFront** is a Content Delivery Network (CDN) service that delivers content with low latency and high transfer speeds by caching content at edge locations worldwide.

### What is a CDN?

A **Content Delivery Network** is a geographically distributed network of servers that:
- **Cache content** at locations closer to users
- **Improve read performance** by reducing latency
- **Reduce load** on origin servers
- **Improve user experience** with faster delivery

### CloudFront Key Characteristics

- **Global edge network**: Hundreds of Points of Presence (edge locations) worldwide
- **Content caching**: Content is cached at edge locations for a TTL (typically 1 day)
- **DDoS protection**: Built-in protection due to worldwide distribution
- **Integration with AWS Shield**: Additional DDoS protection
- **AWS WAF integration**: Web Application Firewall for security
- **SSL/TLS support**: Encrypted content delivery

### Common Use Cases

1. **Static website hosting** - CSS, JavaScript, images
2. **API acceleration** - Reduce latency for API requests
3. **Dynamic content** - Cache dynamic pages where appropriate
4. **Large file downloads** - Accelerate software/media distribution
5. **Live streaming** - Deliver live video globally
6. **Video on demand** - Cache pre-recorded video
7. **Application acceleration** - Speed up web application delivery

---

## CloudFront Origins

An **origin** is the source of content that CloudFront will cache and deliver. CloudFront supports three main types of origins.

### S3 Bucket Origin

**What it is:**
- S3 bucket serves as the origin for CloudFront
- CloudFront caches files from S3 and delivers them at the edge
- Users cannot directly access S3 bucket; only through CloudFront

**Use cases:**
- Distributing files globally
- Caching static content
- Uploading files through CloudFront to S3

**Security:**
- **Origin Access Control (OAC)** - Modern approach
  - CloudFront can only access S3 through special OAC identity
  - S3 bucket policy restricts access to OAC only
  - Better security than legacy OAI (Origin Access Identity)

**Configuration:**
```bash
# Create OAC and attach to CloudFront distribution
# Then configure S3 bucket policy to allow only OAC
```

### VPC Origin (Private)

**What it is:**
- Applications hosted in VPC private subnets
- CloudFront forwards requests to private resources
- Resources remain private (not exposed to internet)

**Supported resources:**
- Private Application Load Balancer (ALB)
- Private Network Load Balancer (NLB)
- Private EC2 instances

**Network connectivity:**
- CloudFront edge locations need network path to private resources
- Typically through AWS Global Accelerator or CloudFront VPC endpoints

### Custom Origin (HTTP)

**What it is:**
- Any public HTTP/HTTPS backend
- Can be S3 website or any HTTP server

**Use cases:**
- S3 website (static website hosting via S3)
- Public Application Load Balancer
- Public NLB
- Public EC2 instances
- On-premises web servers
- Third-party HTTP endpoints

**Configuration requirements:**
- Must be publicly accessible
- Must respond to HTTP/HTTPS requests
- Must be reachable from CloudFront edge locations

---

## CloudFront vs S3 Cross-Region Replication

Both can serve content globally, but they have different characteristics:

### CloudFront

**How it works:**
- Content cached at edge locations for TTL
- Cache hit = content served from edge (fast)
- Cache miss = content fetched from origin, cached, then served

**Characteristics:**
- ✓ Global edge network with hundreds of locations
- ✓ Simple setup for global distribution
- ✓ Cache-based (TTL controlled)
- ✓ Good for static content served everywhere
- ✗ Not real-time (waits for TTL to refresh)
- ✗ Cache invalidation required for immediate updates

**Best for:**
- Static content served globally
- Improved performance for worldwide users
- Content that doesn't change frequently

### S3 Cross-Region Replication (CRR)

**How it works:**
- Objects automatically replicated to other regions
- Near real-time replication
- Each region has full copy of data

**Characteristics:**
- ✓ Near real-time updates
- ✓ Read-only copies in multiple regions
- ✓ Data always available locally in each region
- ✗ Must configure for each region
- ✗ More complex management
- ✗ Higher cost (per-region storage + transfer)

**Best for:**
- Dynamic content needing low latency in specific regions
- Compliance requirements (data residency)
- Few target regions (2-3 strategically placed)

### Comparison

| Aspect | CloudFront | S3 CRR |
|--------|-----------|--------|
| **Coverage** | Global (all edges) | Only configured regions |
| **Update Speed** | Depends on TTL | Near real-time |
| **Setup** | One distribution | Per region |
| **Read-only** | Yes | Yes (after replication) |
| **Cost** | Lower | Higher |
| **Best for** | Static content | Dynamic, few regions |

---

## CloudFront Caching

### How Caching Works

1. Client requests content from CloudFront
2. CloudFront checks cache at edge location
3. **Cache hit**: Return cached content (fast)
4. **Cache miss**: Fetch from origin, cache it, return to client
5. Cached content expires based on TTL

### Cache Key

A **Cache Key** is a unique identifier for every object in the cache that determines whether a request results in a cache hit or miss.

**Default Cache Key components:**
- Hostname (domain name)
- Resource portion of URL path

**Important:** Different requests with same Cache Key get same response from cache

**Example:**
```
Request 1: https://example.com/image.jpg?size=300
Request 2: https://example.com/image.jpg?size=300
→ Same Cache Key → Cache Hit (same response)

Request 1: https://example.com/image.jpg?size=300
Request 2: https://example.com/image.jpg?size=400
→ Different Cache Key (without query string in key) → Cache Hit
→ Same Cache Key (with query string in key) → Cache Miss
```

### Cache Policy

**Cache Policy** controls:
- Which elements (headers, cookies, query strings) are included in Cache Key
- TTL for cached objects
- Cache behavior (compress, forward to origin, etc.)

**TTL Control:**
- Minimum: 0 seconds (no caching)
- Maximum: 1 year
- Default: Set by Cache Policy
- Can be overridden by origin (via Cache-Control header)

#### Cache Policy: HTTP Headers

**None (default, best performance):**
- No headers included in Cache Key
- Headers not forwarded to origin
- Single cached version for all header variations

**Whitelist:**
- Only specified headers included in Cache Key
- Specified headers forwarded to origin
- Multiple cached versions if header values differ

**Example:**
```
Cache Policy: Whitelist "User-Agent"

Request 1: Accept-Language: en-US
Request 2: Accept-Language: fr-FR
→ Same Cache Key (Accept-Language not whitelisted) → Cache Hit

Request 1: User-Agent: Chrome
Request 2: User-Agent: Firefox
→ Different Cache Key → Multiple cached versions
```

#### Cache Policy: Query Strings

**None (default):**
- Query strings NOT in Cache Key
- Query strings NOT forwarded
- Best caching performance
- Good when query string doesn't affect response

**Whitelist:**
- Only specified query strings in Cache Key
- Only specified query strings forwarded
- Multiple cached versions for different values

**Include All-Except:**
- All query strings in Cache Key except specified list
- All query strings forwarded except specified list
- Good for ignoring tracking parameters

**All:**
- All query strings in Cache Key
- All query strings forwarded
- Worst caching performance
- Use when response varies by query string

#### Cache Policy: Cookies

**None (default):**
- Cookies NOT in Cache Key
- Cookies NOT forwarded
- Best caching performance

**Whitelist:**
- Only specified cookies in Cache Key
- Only specified cookies forwarded
- Good for session-specific content

**All:**
- All cookies in Cache Key
- All cookies forwarded
- Worst caching performance

### Origin Request Policy

**Origin Request Policy** controls what information is sent to the origin server **without including it in the Cache Key**.

**Purpose:** Reduce duplicated cached content while still sending needed info to origin

**Example scenario:**
```
Viewer sends: Authorization header, session_id cookie, ref query string
Cache Policy: Include only "ref" in Cache Key
Origin Request Policy: Forward Authorization, session_id, and ref

Result:
- Two requests with different Authorization headers = same cache hit
- But origin receives both Authorization headers for processing
- Less caching duplication
```

**Can include:**
- HTTP headers (None, Whitelist, All)
- Cookies (None, Whitelist, All)
- Query strings (None, Whitelist, All)

**Ability to add CloudFront headers:**
- Can add CloudFront-provided headers
- Can add custom headers to origin requests
- Not included in Cache Key

---

## Cache Invalidations

When you update content on the origin, CloudFront doesn't know about it and serves stale cached content until TTL expires.

### CloudFront Invalidation

**Purpose:** Force CloudFront to refresh specific cached objects before TTL expires

**How it works:**
1. Request invalidation for specific paths
2. CloudFront marks those paths as invalid
3. Next request for invalidated path fetches fresh content from origin
4. Then caches new content

**Invalidation patterns:**
- `/*` - Invalidate all files (expensive)
- `/images/*` - Invalidate specific directory
- `/index.html` - Invalidate specific file
- `/api/v2/*` - Invalidate API version

**API:**
```bash
aws cloudfront create-invalidation \
  --distribution-id DISTRIBUTION_ID \
  --paths "/index.html" "/images/*" "/api/v2/*"
```

**Cost:** 
- Charges per invalidation request
- First 3,000 per month free
- After that, additional charges apply

**Best practice:** Minimize invalidations by using good Cache Policy and TTL settings

---

## Cache Behaviors

**Cache Behaviors** allow you to configure different caching rules for different URL paths in a single CloudFront distribution.

### How Cache Behaviors Work

1. Client requests content with specific URL path
2. CloudFront matches path to a Cache Behavior
3. Applies Cache Policy and Origin Request Policy for that Behavior
4. Routes to specified origin

### Multiple Paths

**Common pattern:**
```
Distribution: example.com
└─ Cache Behaviors:
   ├─ /images/*        → S3 bucket (images)
   ├─ /api/*           → Application Load Balancer
   ├─ /videos/*        → Video streaming origin
   └─ /*               → Default cache behavior (S3 bucket)
```

**Default Cache Behavior:**
- URL pattern: `/*` (catch-all)
- Always processed last
- Fallback for URLs not matching other behaviors

### Use Case: Separating Static and Dynamic Content

**Strategy for maximizing cache hits:**
```
CloudFront Distribution
├─ Static content (images, CSS, JS)
│  ├─ Origin: S3 bucket
│  ├─ Cache Policy: Aggressive caching (long TTL)
│  ├─ No headers/cookies in Cache Key
│  └─ High cache hit ratio
│
└─ Dynamic content (API, HTML)
   ├─ Origin: Application Load Balancer
   ├─ Cache Policy: Conservative (short TTL)
   ├─ Include session cookie in Cache Key
   └─ Lower cache hit ratio (by design)
```

**Benefit:** Static content gets excellent cache performance without affecting dynamic content

---

## CloudFront with ALB or EC2

### Architecture Options

#### Option 1: Private ALB with VPC Origin (Recommended)

```
Users
  ↓
CloudFront Edge Location
  ↓
CloudFront (VPC origin)
  ↓
Private Subnet
  ↓
Private Application Load Balancer
  ↓
EC2 Instances (private)
```

**Security:**
- ALB and EC2 instances are private (not on internet)
- Only CloudFront can access them
- Reduced attack surface

#### Option 2: Public ALB with Custom Origin

```
Users
  ↓
CloudFront Edge Location
  ↓
CloudFront (HTTP origin)
  ↓
Public Subnet
  ↓
Public Application Load Balancer
  ↓
EC2 Instances
```

**Security:**
- ALB and EC2 are public (exposed to internet)
- Use security groups to restrict access
- Cloud Front edge locations need access
- EC2 instances can be private (behind ALB)

### Security Group Configuration

**For Private ALB:**
- Allow traffic from CloudFront edge location IPs
- Edge locations have public IP addresses
- AWS provides list: `http://d7uri8nf7uskq.cloudfront.net/tools/list-cloudfront-ips`

**For Public ALB:**
- Allow traffic from CloudFront edge location IPs
- OR allow traffic from any source (0.0.0.0/0) since behind ALB

**For Private EC2 behind ALB:**
- Allow traffic from ALB security group
- Don't expose directly to internet

---

## CloudFront Geo-Restriction

**Geo-Restriction** controls which geographic regions can access your content.

### Use Cases

- **Copyright protection**: Restrict content to specific countries
- **Licensing agreements**: Distribute content only where licensed
- **Compliance**: Meet regional data laws
- **DMCA compliance**: Digital Millennium Copyright Act requirements

### How It Works

**Country determination:**
- Uses third-party Geo-IP database
- Based on viewer's IP address location
- Updated regularly

### Allowlist vs Blocklist

**Allowlist (Whitelist):**
- Specify countries where access IS allowed
- Users outside list cannot access
- More restrictive

**Blocklist (Blacklist):**
- Specify countries where access is NOT allowed
- Users outside list can access
- Less restrictive

### Configuration

```bash
# Allow only specific countries
aws cloudfront create-distribution \
  --geo-restriction-type whitelist \
  --locations us ca uk de

# Block specific countries
aws cloudfront create-distribution \
  --geo-restriction-type blacklist \
  --locations ru cn ir
```

---

## CloudFront Signed URLs and Cookies

**Signed URLs and Cookies** allow you to control access to content, restricting who can access specific files and for how long.

### Use Cases

1. **Premium/Paid content** - Only paying customers
2. **Temporary access** - Time-limited sharing
3. **User-specific content** - Different users, different content
4. **Private videos** - Restrict to authenticated users

### Signed URL

**Purpose:** Grant access to a specific file for a limited time

**How it works:**
1. Client authenticates with your application
2. Application generates Signed URL for requested file
3. Application returns URL to client
4. Client uses URL to access file via CloudFront
5. CloudFront verifies signature and TTL
6. If valid, serves content

**Characteristics:**
- One signed URL per file
- Can include IP restrictions
- Can include date/expiration
- Cannot be modified by user

### Signed Cookie

**Purpose:** Grant access to multiple files using a single credential

**How it works:**
1. Client authenticates with application
2. Application sets Signed Cookie in response
3. Browser stores cookie
4. Browser includes cookie with all requests to CloudFront
5. CloudFront verifies cookie signature
6. If valid, serves requested content

**Characteristics:**
- One cookie for multiple files
- Better for multi-file access
- User can't modify cookie (signed)
- Useful for website with many protected files

### CloudFront Signed URL vs S3 Pre-Signed URL

| Feature | CloudFront Signed URL | S3 Pre-Signed URL |
|---------|----------------------|-------------------|
| **Path** | Access to any path | Must specify exact object |
| **Scope** | Distribution-level | S3 object-level |
| **Signer** | Account-level key pair | IAM credentials |
| **Caching** | Leverages CloudFront cache | Direct S3 access |
| **IP restriction** | Yes | Limited |
| **Lifetime** | Flexible | Limited |
| **Use** | General content control | Direct S3 sharing |

### Signed URL Process

**Two types of signers (who can sign):**

1. **Trusted Key Group (Recommended)**
   - You generate public/private key pair (RSA 2048 or ECDSA 256, PEM format)
   - Upload public key to CloudFront
   - Add public key to a CloudFront Key Group
   - Applications use private key to sign URLs/cookies
   - CloudFront uses public key to verify signatures
   - **Managed via CloudFront API** - enables automation and key rotation
   - **No root user required** - follows AWS best practices
   - **IAM policies control access** - can restrict who creates/deletes keys, enforce MFA, set network/time restrictions
   - **More flexibility** - up to 4 key groups per distribution, up to 5 public keys per key group
   - **Better for key rotation** - can add new key, update application, then remove old key without invalidating active URLs/cookies

2. **CloudFront Key Pair (Legacy - Not Recommended)**
   - Requires **AWS root account credentials** to create and manage
   - Must use **AWS Management Console** (no API automation)
   - Management via Management Console only (cannot be automated)
   - Limited to **2 active key pairs per AWS account**
   - **Cannot use IAM policies** - root account full control only
   - **Difficult to rotate** - no simultaneous key overlap capability
   - **AWS best practice violation** - using root user for routine operations
   - Provided for backward compatibility only

**Signing process:**

**Creating a Key Pair (for Trusted Key Group):**
```bash
# Generate RSA key pair (2048 bits)
openssl genrsa -out private_key.pem 2048

# Extract public key
openssl rsa -pubout -in private_key.pem -out public_key.pem

# For Java - convert to DER format
openssl pkcs8 -topk8 -nocrypt -in private_key.pem -inform PEM -out private_key.der -outform DER
```

**Using the Private Key to Sign URLs:**
```python
import boto3
from botocore.signers import CloudFrontSigner
from datetime import datetime, timedelta

# Load private key
with open('private_key.pem', 'rb') as f:
    private_key = f.read()

# Create signer with key ID (from CloudFront console)
cf_signer = CloudFrontSigner(
    key_id='APKAJXYZ123456',  # Public Key ID from CloudFront
    private_key=private_key
)

# Generate signed URL valid for 1 hour
signed_url = cf_signer.generate_presigned_url(
    url='https://d123.cloudfront.net/premium-video.mp4',
    date_less_than=datetime.utcnow() + timedelta(hours=1)
)

print(signed_url)
```

**Key Rotation Best Practice:**
1. Create new key pair, upload public key to CloudFront
2. Add public key to existing key group (or create new key group)
3. Update application to use new private key
4. Verify signed URLs with new key are working
5. **Wait for old URLs/cookies to expire** (important!)
6. Remove old public key from key group
7. Old URLs/cookies automatically fail after removal

---

## CloudFront Pricing

### Cost Factors

CloudFront pricing varies based on:
- **Data transfer out** (GB) - Most significant cost
- **HTTP requests** (number of requests)
- **Edge location** - Different regions have different rates

### Price Classes

**Price Class 100 (Cheapest):**
- Only least expensive regions
- Lowest cost
- Covers ~30% of regions
- Use when global coverage not needed

**Price Class 200 (Balanced):**
- Most regions except most expensive
- Mid-range cost
- Covers ~80% of regions
- Good balance for most use cases

**Price Class All (Best Coverage):**
- All CloudFront edge locations
- Highest cost
- Best global performance
- Use when global coverage critical

**Configuration:**
```bash
aws cloudfront create-distribution \
  --price-class PriceClass_100  # or 200, All
```

### Cost Optimization

1. **Use Price Classes** - Reduce regions if global coverage not needed
2. **Cache aggressively** - Longer TTL = fewer origin requests
3. **Use compression** - Reduce data transferred
4. **Monitor usage** - Watch for unexpectedly high costs
5. **Origin Shield** - Optional extra caching layer (added cost)

---

## CloudFront Field-Level Encryption

**Field-Level Encryption** encrypts sensitive form fields before they reach your origin, adding an extra security layer.

### How It Works

1. User submits form with sensitive data (e.g., credit card)
2. CloudFront encrypts specified fields using public key
3. HTTPS encrypts entire request
4. Origin receives encrypted fields
5. Only origin (with private key) can decrypt

### Use Cases

- **Credit card numbers** - PCI-DSS compliance
- **Social security numbers** - Identity protection
- **Personal information** - Privacy protection
- **Sensitive form data** - Application-level security

### Configuration

1. Create asymmetric key pair
2. Upload public key to CloudFront
3. Specify fields to encrypt in distribution
4. Up to 10 fields per distribution
5. Origin decrypts using private key

```bash
# Specify sensitive fields
Fields to encrypt:
- credit_card_number
- cvv
- ssn
```

**Security benefits:**
- ✓ End-to-end encryption
- ✓ Only origin can decrypt
- ✓ Adds layer beyond HTTPS
- ✓ Compliant with strict regulations

---

## CloudFront Real-Time Logs

**Real-Time Logs** give you real-time visibility into CloudFront requests.

### How It Works

1. CloudFront receives requests at edge
2. Logs delivered in near real-time to Kinesis Data Streams
3. Process with Lambda or other services
4. Monitor, analyze, take actions

### Configuration Options

**Sampling Rate:**
- Percentage of requests to log (1-100%)
- 100% = all requests logged
- Lower % = fewer costs but less visibility

**Specific Fields:**
- Choose which request fields to log
- Reduce data volume
- Focus on relevant information

**Cache Behaviors:**
- Apply to specific URL patterns
- Log only traffic you care about
- Different sampling for different paths

### Use Cases

1. **Performance monitoring** - Real-time latency analysis
2. **Security** - Detect suspicious activity
3. **Debugging** - Troubleshoot delivery issues
4. **Analytics** - Understand user access patterns
5. **Compliance** - Audit trail for regulations

### Architecture

```
CloudFront Edges
    ↓
Kinesis Data Streams
    ├─→ Lambda (real-time processing)
    ├─→ Kinesis Data Firehose (persist to S3)
    └─→ Custom applications
```

---

## Origin Groups (High Availability)

**Origin Groups** provide failover and high availability for your origins.

### How Origin Groups Work

1. Configure primary and secondary origins
2. CloudFront sends requests to primary
3. If primary fails (returns error status), failover to secondary
4. Automatic failover improves availability

### Setup

```
Origin Group
├─ Primary Origin (S3 bucket in us-east-1)
└─ Secondary Origin (S3 bucket in us-west-2)

Request → Primary (us-east-1)
If error → Failover to Secondary (us-west-2)
```

### Use Cases

1. **Regional high availability** - Multiple S3 buckets
2. **Origin maintenance** - Fail over during updates
3. **Disaster recovery** - Automatic failover on outage
4. **Load balancing** - Distribute across origins

### Configuration

```bash
aws cloudfront create-distribution \
  --origin-group-id my-origin-group \
  --primary-member-origin primary-bucket \
  --failover-member-origin secondary-bucket \
  --failover-criteria status_code=500-599
```

---

## References

- [CloudFront Documentation][1]
- [CloudFront Caching][2]
- [CloudFront Policies][3]
- [CloudFront Signed URLs and Cookies][4]
- [CloudFront Pricing][5]
- [CloudFront Real-Time Logs][6]
- [Field-Level Encryption][7]

[1]: https://docs.aws.amazon.com/cloudfront/latest/developerguide/Introduction.html
[2]: https://docs.aws.amazon.com/cloudfront/latest/developerguide/cache-hit-ratio.html
[3]: https://docs.aws.amazon.com/cloudfront/latest/developerguide/policies.html
[4]: https://docs.aws.amazon.com/cloudfront/latest/developerguide/private-content.html
[5]: https://docs.aws.amazon.com/cloudfront/latest/developerguide/CloudFrontPricing.html
[6]: https://docs.aws.amazon.com/cloudfront/latest/developerguide/real-time-logs.html
[7]: https://docs.aws.amazon.com/cloudfront/latest/developerguide/field-level-encryption.html
