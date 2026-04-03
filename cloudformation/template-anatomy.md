# AWS CloudFormation — Template Anatomy

A **CloudFormation template** is a text file (YAML or JSON) that describes AWS resources and optional metadata. CloudFormation reads the template and drives API calls to create a **stack** [1].

---

## Template Sections (Building Blocks)

| Section | Required? | Role |
|--------|-------------|------|
| `AWSTemplateFormatVersion` | Optional | Template format version (currently `2010-09-09`) [2] |
| `Description` | Optional | Short description of the template [2] |
| `Metadata` | Optional | UI or tooling hints (e.g. `AWS::CloudFormation::Interface`) [2] |
| `Parameters` | Optional | Inputs supplied at stack create/update time [2] |
| `Mappings` | Optional | Static key/value tables (e.g. per-Region AMI map) [2] |
| `Conditions` | Optional | Boolean expressions controlling resource/output creation [2] |
| `Transform` | Optional | Macros / nested stacks / serverless transforms [2] |
| `Resources` | **Required** | AWS resources to create [2] |
| `Outputs` | Optional | Exported values and stack outputs [2] |

**“Helpers” in practice:** **intrinsic functions** (`Ref`, `Fn::GetAtt`, etc.) and **references** between resources tie sections together [2].

---

## YAML vs JSON

| Topic | YAML | JSON |
|------|------|------|
| Readability | Usually better for humans | Verbose; many quotes/braces |
| Comments | Supported (`#`) | Not supported |
| Multi-line strings | Natural (`|`, `>`) | Awkward for UserData, policies |
| Course take | **Preferred** for CloudFormation | Valid but painful for large templates |

CloudFormation accepts both; **YAML is the usual choice** for new work [1].

---

## Minimal Skeleton (YAML)

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: Example stack

Parameters:
  # ...

Resources:
  MyResource:
    Type: AWS::Service::ResourceType
    Properties:
      # ...

Outputs:
  # ...
```

---

## How Sections Fit Together

- **Parameters** → user input at deploy time.
- **Mappings** → fixed lookup tables (often Region/account/env).
- **Conditions** → branch logic (e.g. create prod-only resources).
- **Resources** → the actual infrastructure; resources reference each other via `Ref` / `Fn::GetAtt`.
- **Outputs** → values for operators or **cross-stack** imports (`Export` + `Fn::ImportValue` in another stack) [2].

---

## References

- [Template anatomy][1]
- [Template sections][2]

[1]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-anatomy.html
[2]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-guide.html
