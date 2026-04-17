# AWS CloudTrail

CloudTrail is the audit and governance service that records API activity in your AWS account.

---

## What CloudTrail records

CloudTrail captures API calls made by:

- AWS Management Console
- AWS CLI
- AWS SDKs
- IAM users and IAM roles
- AWS services acting on your behalf

CloudTrail is enabled by default for event history.

---

## Trail scope and delivery

- A trail can be:
  - **Multi-region** (recommended default in many setups).
  - **Single-region**.
- Events can be delivered to:
  - Amazon S3 (long-term archive).
  - CloudWatch Logs (query/alerts integration).

---

## Event categories

### Management events

- Control-plane operations on AWS resources.
- Examples: IAM policy attachment, subnet creation, trail configuration.
- Can separate read-only vs write operations.

### Data events

- High-volume data-plane operations.
- Not enabled by default due to volume/cost.
- Examples:
  - S3 object-level API calls (`GetObject`, `PutObject`, `DeleteObject`).
  - Lambda `Invoke` events.

### CloudTrail Insights events

- Optional anomaly detection over management write activity.
- Detects unusual API call patterns (spikes, operational anomalies).
- Insights can emit events for automation via EventBridge.

---

## Retention and long-term analysis

- Event history in CloudTrail console has limited retention window.
- For long-term retention and analytics:
  - Deliver logs to S3.
  - Query with Athena.

---

## CloudTrail with EventBridge

A common incident response pattern:

1. CloudTrail records API call.
2. EventBridge rule matches event pattern.
3. Trigger SNS/Lambda/Step Functions for alerting or remediation.

Useful for security-sensitive actions (for example IAM or network policy changes).

---

## Exam-oriented tips

- If a question asks "who deleted/changed resource X?" -> check **CloudTrail** first.
- If asking for metric trends and operational thresholds -> **CloudWatch**.
- If asking for distributed request-path latency/errors -> **X-Ray**.

---

## References

- [AWS CloudTrail User Guide][1]
- [How CloudTrail works][2]
- [CloudTrail event reference][3]
- [Logging data events with CloudTrail][4]
- [CloudTrail Insights][5]
- [CloudTrail logs in CloudWatch Logs][6]
- [Querying CloudTrail logs with Athena][7]

[1]: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-user-guide.html
[2]: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/how-cloudtrail-works.html
[3]: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-events.html
[4]: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-data-events-with-cloudtrail.html
[5]: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-insights-events-with-cloudtrail.html
[6]: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/send-cloudtrail-events-to-cloudwatch-logs.html
[7]: https://docs.aws.amazon.com/athena/latest/ug/cloudtrail-logs.html
