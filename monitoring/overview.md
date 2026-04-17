# AWS Monitoring, Troubleshooting, and Audit — Overview

This section covers how to observe application health, troubleshoot distributed systems, and audit account activity.

Core services:

- **CloudWatch**: metrics, logs, alarms, synthetic checks.
- **EventBridge**: event routing for operational automation.
- **X-Ray**: distributed tracing for latency/error analysis.
- **CloudTrail**: audit trail of API activity in AWS accounts.
- **ADOT**: OpenTelemetry-based observability pipeline on AWS.

---

## Why this matters

Users do not care how your app is deployed; they care that it is available, fast, and reliable.

Monitoring and audit answer different but complementary questions:

- **CloudWatch**: "Is my system healthy right now? Is it degrading?"
- **X-Ray**: "Where exactly is a request slow or failing?"
- **CloudTrail**: "Who changed what, when, and via which API call?"
- **EventBridge**: "How do I automatically react to operational events?"

---

## Exam-oriented mental model

- Use **CloudWatch Metrics + Alarms** for thresholds and autoscaling reactions.
- Use **CloudWatch Logs + Logs Insights** for log analytics and troubleshooting.
- Use **X-Ray** for request path, service map, bottleneck and fault diagnosis.
- Use **CloudTrail** for governance/compliance and change investigations.
- Use **EventBridge** to trigger automated remediations or notifications.

---

## Typical troubleshooting flow

1. Alarm fires in **CloudWatch**.
2. Investigate app/system logs in **CloudWatch Logs / Logs Insights**.
3. Trace impacted requests in **X-Ray** to isolate slow/faulty dependency.
4. Check **CloudTrail** for recent API/config changes around incident time.
5. Add or improve **EventBridge** rules for proactive remediation.

---

## References

- [Amazon CloudWatch documentation][1]
- [Amazon EventBridge documentation][2]
- [AWS X-Ray Developer Guide][3]
- [AWS CloudTrail User Guide][4]
- [AWS Distro for OpenTelemetry docs][5]

[1]: https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html
[2]: https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-what-is.html
[3]: https://docs.aws.amazon.com/xray/latest/devguide/aws-xray.html
[4]: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-user-guide.html
[5]: https://aws-otel.github.io/docs/introduction
