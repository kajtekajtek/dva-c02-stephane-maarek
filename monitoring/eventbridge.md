# Amazon EventBridge

Amazon EventBridge is an event bus service used to route events from AWS services, SaaS partners, and custom apps to downstream targets for automation.

---

## Core building blocks

- **Event bus**: receives events.
  - Default event bus (AWS services).
  - Partner event bus (SaaS integrations).
  - Custom event bus (application-defined).
- **Rule**: matches events by pattern or schedule.
- **Target**: destination action (Lambda, SNS, SQS, Step Functions, ECS task, etc.).

---

## Rule types

### Schedule rules

- Trigger on cron/rate expressions (for periodic jobs and maintenance tasks).

### Event pattern rules

- Match incoming event JSON by source, detail type, account, region, and fields in `detail`.
- Useful for reactive automation (for example failed builds, EC2 state changes, CloudTrail API calls).

---

## Common targets

- AWS Lambda
- Amazon SNS
- Amazon SQS
- AWS Step Functions
- ECS tasks / AWS Batch
- CodeBuild / CodePipeline
- Kinesis Data Streams
- Systems Manager actions

---

## Schema Registry

- EventBridge can infer and register event schemas.
- Helps generate typed code bindings and reduce payload-handling errors.
- Supports schema versioning as events evolve.

---

## Event archive and replay

- You can archive events from a bus (all or filtered).
- Replaying archived events allows reprocessing for debugging, backfills, or new consumers.

---

## Resource-based policies and multi-account patterns

- Event buses support resource-based policies.
- Use them to allow `PutEvents` from other AWS accounts/regions.
- Common pattern: centralize organization-wide events into a shared event bus account.

---

## EventBridge + CloudTrail

- CloudTrail emits API activity events.
- EventBridge can match those events and trigger immediate notifications/remediation.

Example ideas:

- Alert when a privileged API is called.
- Trigger workflow when security group rules are changed.
- Notify on root user sign-in events.

---

## References

- [What is Amazon EventBridge?][1]
- [Event buses][2]
- [Event patterns][3]
- [Schedule expressions][4]
- [EventBridge Schema Registry][5]
- [Archiving and replaying events][6]
- [Using resource-based policies for EventBridge][7]
- [Events from AWS services via EventBridge][8]

[1]: https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-what-is.html
[2]: https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-event-bus.html
[3]: https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-event-patterns.html
[4]: https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-scheduled-rule-pattern.html
[5]: https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-schema.html
[6]: https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-archive.html
[7]: https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-event-bus-perms.html
[8]: https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-service-event.html
