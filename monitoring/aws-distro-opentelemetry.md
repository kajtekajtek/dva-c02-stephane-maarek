# AWS Distro for OpenTelemetry (ADOT)

AWS Distro for OpenTelemetry (ADOT) is an AWS-supported distribution of the open-source OpenTelemetry project.

It standardizes telemetry collection across environments and can export to multiple backends.

---

## What ADOT provides

- OpenTelemetry-compatible APIs, SDKs, and collectors.
- Collection of:
  - Distributed traces
  - Metrics
  - AWS resource/context metadata
- Auto-instrumentation options to reduce code changes.

---

## Where ADOT runs

- EC2
- ECS
- EKS
- Fargate
- Lambda
- On-prem workloads

---

## Export destinations

ADOT can send telemetry to:

- AWS X-Ray
- Amazon CloudWatch
- Amazon Managed Service for Prometheus
- Partner observability platforms

This multi-destination model is a key reason to adopt ADOT in modern observability stacks.

---

## ADOT vs X-Ray-only approach

- X-Ray is excellent for AWS-native distributed tracing.
- ADOT is preferred when you need:
  - OpenTelemetry standards
  - Vendor portability
  - Simultaneous export to several backends
  - Shared instrumentation model across cloud and on-prem

---

## Exam takeaway

- If question mentions **OpenTelemetry standardization** or **multiple telemetry backends**, ADOT is usually the best fit.
- If question is solely AWS-native request tracing/service map, X-Ray alone may be enough.

---

## References

- [AWS Distro for OpenTelemetry introduction][1]
- [ADOT components][2]
- [Sending telemetry with ADOT Collector][3]
- [OpenTelemetry project][4]

[1]: https://aws-otel.github.io/docs/introduction
[2]: https://aws-otel.github.io/docs/components
[3]: https://aws-otel.github.io/docs/getting-started
[4]: https://opentelemetry.io/docs/
