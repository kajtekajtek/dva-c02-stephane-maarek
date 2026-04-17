# CloudTrail vs CloudWatch vs X-Ray

Quick comparison for troubleshooting and exam scenarios.

| Service | Primary purpose | Typical data | Best for | Not ideal for |
|---|---|---|---|---|
| **CloudWatch** | Operational monitoring and alerting | Metrics, logs, alarms, synthetic checks | Health monitoring, thresholds, dashboards, alerting | Deep API audit attribution |
| **X-Ray** | Distributed request tracing | Traces (segments/subsegments), latency/error metadata | Pinpointing bottlenecks/faults across microservices | Broad account-level API audit history |
| **CloudTrail** | Governance, compliance, and audit | AWS API event history | "Who did what, when?" and change forensics | Real-time app latency diagnostics |

---

## How they work together

- **CloudWatch** detects symptom (high latency/error rate).
- **X-Ray** identifies root cause along the request path.
- **CloudTrail** verifies whether config/API changes triggered or worsened the incident.

---

## Exam heuristics

- "Track CPU, memory trends, trigger alarm" -> **CloudWatch**.
- "Trace request through API Gateway -> Lambda -> DynamoDB" -> **X-Ray**.
- "Find who deleted an S3 bucket / changed IAM policy" -> **CloudTrail**.
- "React automatically to an API call event" -> **CloudTrail + EventBridge**.

---

## References

- [CloudWatch documentation][1]
- [AWS X-Ray Developer Guide][2]
- [AWS CloudTrail User Guide][3]
- [Amazon EventBridge documentation][4]

[1]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html
[2]: https://docs.aws.amazon.com/xray/latest/devguide/aws-xray.html
[3]: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-user-guide.html
[4]: https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-what-is.html
