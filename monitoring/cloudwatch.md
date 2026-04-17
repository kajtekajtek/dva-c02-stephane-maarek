# Amazon CloudWatch

CloudWatch is AWS's core operational observability service for **metrics**, **logs**, **alarms**, and **synthetic monitoring**.

---

## CloudWatch Metrics

- A **metric** is a time-ordered data series (for example `CPUUtilization`).
- Metrics are grouped into **namespaces** (AWS service or custom namespaces).
- **Dimensions** are key-value attributes used to segment metric streams (for example instance ID, environment, service name).
- CloudWatch supports dashboards to visualize metric trends over time.

### EC2 monitoring frequency

- **Basic monitoring**: 5-minute granularity (default).
- **Detailed monitoring**: 1-minute granularity (paid; some free-tier allowance exists).
- EC2 memory is **not available by default**; publish it as a custom metric (typically via Unified Agent).

### Custom metrics

- Publish with `PutMetricData`.
- Common uses: memory, disk usage, active users, business KPIs.
- Resolution:
  - Standard: 60 seconds.
  - High-resolution: 1/5/10/30 seconds (higher cost).
- Backdated and future timestamps are accepted only within documented limits.
  - as much as two weeks before the current  date, and as much as 2 hours after the current day and time

---

## CloudWatch Logs

Core concepts:

- **Log Group**: logical container (often per application/workload).
- **Log Stream**: ordered stream of events (often per instance/container/function).
- Set retention from short periods to long-term, including never expire.
- CloudWatch Logs encrypts data at rest by default; optional customer-managed KMS keys can be used.

Common log sources:

- Lambda function logs.
- ECS / EKS container logs.
- EC2 / on-prem logs via agent.
- API Gateway, VPC Flow Logs, Route 53 query logs.
- CloudTrail (if configured to deliver to CloudWatch Logs).

Destinations/integrations:

- Export to S3 (`CreateExportTask`) for archive/offline analysis.
- Real-time subscriptions to Kinesis Data Streams, Kinesis Data Firehose, or Lambda.
- Integration with OpenSearch for search use cases.

### Logs Insights

- Query engine for CloudWatch Logs.
- Good for ad-hoc troubleshooting and aggregate analysis.
- Supports field extraction, filtering, stats, sorting, and dashboards.
- Not meant as a stream processing engine.

### Metric Filters

- Convert matching log patterns into CloudWatch metrics.
- Typical use: create alarms from log events (for example counting `ERROR` events).
- Filters are **not retroactive**: they only process events ingested after filter creation.

---

## CloudWatch agents (EC2 and on-prem)

### CloudWatch Logs agent (legacy)

- Sends logs to CloudWatch Logs.
- Limited compared to Unified Agent.

### CloudWatch Unified Agent (recommended)

- Sends logs and system-level metrics from EC2/on-prem.
- Metrics include detailed CPU, memory, disk, network, process, and swap information.
- Supports centralized config management using SSM Parameter Store.

---

## CloudWatch Alarms

Alarms evaluate metrics and move between states:

- `OK`
- `INSUFFICIENT_DATA`
- `ALARM`

Alarm actions include:

- Notify via SNS.
- Trigger Auto Scaling actions.
- Perform EC2 actions (stop/terminate/reboot/recover).

### Composite alarms

- Built from other alarms using `AND` / `OR` logic.
- Useful for reducing alert noise and requiring multi-signal confirmation.

### EC2 instance recovery alarm

- `StatusCheckFailed_System` can trigger automatic recovery for supported scenarios.
- Recovery attempts to preserve instance identity characteristics (for example IP/metadata behavior as documented).

### Alarm testing

You can force alarm state for testing:

```bash
aws cloudwatch set-alarm-state \
  --alarm-name "myalarm" \
  --state-value ALARM \
  --state-reason "testing purposes"
```

---

## CloudWatch Synthetics

Synthetics canaries run scripted checks against APIs and web endpoints to simulate user journeys.

Capabilities:

- Validate availability and latency.
- Capture screenshots/HAR files.
- Integrate with CloudWatch Alarms for early warning.
- Run once or on schedules.

Blueprints include heartbeat checks, API checks, broken-link checks, visual monitoring, and workflow testing.

---

## References

- [CloudWatch concepts][1]
- [Metrics and dimensions][2]
- [Publishing custom metrics][3]
- [CloudWatch Logs][4]
- [CloudWatch Logs Insights][5]
- [CloudWatch Logs subscription filters][6]
- [CloudWatch unified agent][7]
- [Using Amazon CloudWatch alarms][8]
- [Composite alarms][9]
- [CloudWatch Synthetics][10]

[1]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html
[2]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html#Dimension
[3]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html
[4]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/WhatIsCloudWatchLogs.html
[5]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AnalyzingLogData.html
[6]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/SubscriptionFilters.html
[7]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Install-CloudWatch-Agent.html
[8]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html
[9]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Create_Composite_Alarm.html
[10]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Synthetics_Canaries.html
