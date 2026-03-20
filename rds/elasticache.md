# Amazon ElastiCache

## ElastiCache Overview

- Managed **in-memory** data store / cache (sub-millisecond latency)
- Supports **Redis OSS** (+ Valkey) and **Memcached** engines
- Reduces load on databases for **read-intensive** workloads
- Makes app stateless by externalizing session state
- AWS manages provisioning, patching, monitoring, failure recovery, backups
- Two deployment models: **Serverless** (auto-scales, no nodes to manage) and **node-based clusters** (fine-grained control over instance types, placement, scaling)
- Using ElastiCache requires **application code changes** — not a drop-in replacement; app must query cache before DB

## Solution Architecture

### DB Cache

1. App requests data from **ElastiCache**
2. **Cache hit** → return data immediately (fast path)
3. **Cache miss** → query DB, write result to cache, return data
4. Subsequent identical requests served from cache → relieves DB pressure

### User Session Store

1. User logs in; app writes session data to **ElastiCache**
2. User's next request hits a **different app instance** (stateless)
3. That instance retrieves the session from ElastiCache → user stays logged in
4. Eliminates sticky sessions — any instance can serve any user

## Redis vs Memcached

| Feature | Redis | Memcached |
| ------- | ----- | --------- |
| Data types | Strings, lists, sets, sorted sets, hashes, bitmaps, HyperLogLog, geospatial, streams | Simple key-value (strings, objects) |
| Multi-threaded | No (single-threaded per shard) | **Yes** (multi-core) |
| High availability (replication) | **Yes** (read replicas, Multi-AZ with auto-failover) | No |
| Persistence / backup & restore | **Yes** (snapshots, AOF) | No (node-based), serverless only |
| Pub/Sub | **Yes** (+ sharded pub/sub in 7.x) | No |
| Sorted sets / ranking | **Yes** | No |
| Transactions / Lua scripting | **Yes** | No |
| Geospatial indexing | **Yes** | No |
| Data partitioning (sharding) | **Yes** (cluster mode enabled) | **Yes** (add/remove nodes) |
| Data tiering (memory + SSD) | **Yes** (6.2+, r6gd nodes) | No |
| Encryption (in-transit / at-rest) | **Yes** (4.0.10+) | In-transit only (1.6.12+) |
| Auto failover | Optional (non-cluster) / Required (cluster mode) | No |
| Scaling model | Vertical (node type upgrade) + horizontal (online resharding) | Horizontal (add/remove nodes) |

**Choose Redis** when you need: complex data structures, persistence, replication, pub/sub, transactions, sorted sets, backup/restore, HA with auto-failover.

**Choose Memcached** when you need: simplest model, multi-threaded performance on large nodes, pure object caching, easy horizontal scale-out/in.

## Caching Strategies

### Caching Implementation Considerations

- **Is it safe to cache data?** Data may be out of date, eventually consistent
- Is data structured well for caching?
    - example: key value caching, or caching of aggregations result
- **What to cache** — data that is read frequently but changed infrequently (user profiles, product catalogs, leaderboards)
- **Cache invalidation** — the hardest part; decide between TTL-based expiry, event-driven invalidation, or write-through updates
- **Consistency** — cached data can be stale; pick a strategy (lazy loading, write-through, or both) matching your app's staleness tolerance
- **Eviction policy** — when cache is full, which keys to remove? (LRU, LFU, TTL-based, etc.)
- **Key design** — choose meaningful, collision-free keys (e.g., `user:{id}`)
- Which caching design pattern is the most appropriate?

### Lazy Loading / Cache-Aside / Lazy Population

- Load data into cache **only when requested** (on demand)
- On **cache hit** → return cached data (1 trip)
- On **cache miss** → query DB → write to cache → return data (3 trips)

**Pros:**
- Only requested data is cached — no wasted space
- Node failure is not fatal — app keeps working (higher latency while cache warms up)

**Cons:**
- **Cache miss penalty** — 3 round trips on miss (noticeable latency)
- **Stale data** — cache is not updated when DB changes; data can become outdated until the key is evicted or expires

#### Python Example

```python
def get_user(user_id):
    record = cache.get(user_id)
    if record is None:
        record = db.query("SELECT * FROM users WHERE id = %s", user_id)
        cache.set(user_id, record)
    return record
```

### Write Through

– Add or Update cache when database is updated

- Every **write** to the DB also writes to the cache
- Data in cache is **never stale** (always current)

**Pros:**
- Cache always in sync with DB — reads always return fresh data

**Cons:**
- **Write penalty** — every write = 2 trips (cache + DB); adds write latency
- **Missing data** on new/replaced nodes — data not in cache until next write; combine with **lazy loading** to fill gaps
- **Cache churn** — most written data may never be read → wasted resources; mitigate with **TTL**

#### Python Example

```python
def save_user(user_id, values):
    record = db.query("UPDATE users SET %s WHERE id = %s", values, user_id)
    cache.set(user_id, record)
    return record
```

### Cache Evictions and Time-to-live (TTL)

- **Cache eviction** — item removed from cache to free space; occurs when memory is full and new items need space
- Eviction policies: **LRU** (Least Recently Used), **LFU** (Least Frequently Used), random, TTL-based
- **TTL** — integer value (seconds or ms) after which a key automatically expires; next read treats it as a cache miss
- TTL keeps data from getting **too stale** without manual invalidation
- Set a **sensible TTL** per data type — e.g., seconds for leaderboards, minutes for session data, hours for product catalogs
- Combine TTL with lazy loading and/or write-through for best results
- Too short TTL → frequent cache misses → more DB load; too long → stale data

## Final words of wisdom

- Lazy Loading / Cache aside is easy to implement and works for many situations as a foundation, especially on the read side
- Write-through is usually combined with Lazy Loading as targeted for the queries or workloads that benefit from this optimization
- Setting a TTL is usually not a bad idea, set it to a sensible value for your application
- Only cache the data that makes sense (user profiles, blogs, etc…)
- Quote: There are only two hard things in Computer Science: cache invalidation and naming things

## References

- [What is Amazon ElastiCache? — ElastiCache User Guide][1]
- [Comparing Valkey, Memcached, and Redis OSS clusters][2]
- [Caching strategies for Memcached — Amazon ElastiCache][3]
- [Redis OSS vs. Memcached — AWS][4]

[1]: https://docs.aws.amazon.com/AmazonElastiCache/latest/UserGuide/WhatIs.html
[2]: https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/SelectEngine.html
[3]: https://docs.aws.amazon.com/AmazonElastiCache/latest/mem-ug/Strategies.html
[4]: https://aws.amazon.com/elasticache/redis-vs-memcached/
