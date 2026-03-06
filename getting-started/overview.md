# AWS Cloud Overview

Amazon Web Services is a cloud provider offering on-demand use of servers and services that scale easily.

## Number Facts

- Launched internally in 2002
- Launched publicly with SQS in 2004
- $90 billion annual revenue in 2023
- 31% of the market in Q1 2024
- Over 1 million active users

## Use Cases

- Building sophisticated, scalable applications
- Applicable to a diverse set of industries
    - Enterprise IT, backup & storage, big data analytics
    - Website hosting, mobile & social apps
    - Gaming

## Global Infrastructure

Regions, Availability Zones, Data Centers, Edge Locations / Points of Presence

### Regions

- A region is a **cluster of data centers**
- Regions all around the world
- Names like us-east-1, eu-west-3, ...
- Most AWS **services are region-scoped**
- Factors that impact choice of the region:
    - Compliance with data governance and legal requirements
    - Proximity to customers for reduced latency
    - Services availability
    - Pricing varying region to region

### Availability Zones

- Each region has many availability zones (from 3 to 6)
    - ap-southeast-2**a**
    - ap-southeast-2**b**
- Each AZ is: 
    - **one or more discrete data center** with redundant power, networking and connectivity
    - **separated from each other** to avoid disaster cascades
    - **connected** with high bandwith, ultra-low latency networks, forming a **region**

### Edge Locations / Points of Presence

- 400+ PoPs (400+ Edge Locations & 10+ Regional Caches) in 90+ cities accross 40+ countries
- Content is delivered to end users with lower latency

