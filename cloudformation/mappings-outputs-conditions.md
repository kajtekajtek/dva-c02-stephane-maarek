# AWS CloudFormation — Mappings, Outputs, Conditions

Three optional sections that control **lookup tables**, **stack outputs**, and **conditional** resource/output creation [1][2][3].

---

## Mappings

**Mappings** are **static** nested dictionaries embedded in the template (e.g. Region → AMI id, env → instance type). Values are known at template authoring time [1].

### Access: `Fn::FindInMap`

```yaml
Fn::FindInMap: [ MapName, TopLevelKey, SecondLevelKey ]
# YAML shorthand:
!FindInMap [ MapName, TopLevelKey, SecondLevelKey ]
```

**Classic use:** AMIs differ per Region — map `AWS::Region` to an AMI id [1].

### Mappings vs Parameters

- **Mappings**: finite, author-controlled lookup tables; good when keys are predictable (Region, AZ, env).
- **Parameters**: free-form or user-specific values at deploy time [1].

---

## Outputs

**Outputs** expose values after stack creation: console, CLI, or other stacks [2].

### Same-Stack Use

- Operators read VPC id, subnet ids, role ARNs, etc.

### Cross-Stack References

1. Export from stack A:

```yaml
Outputs:
  VpcId:
    Value: !Ref MyVpc
    Export:
      Name: !Sub '${AWS::StackName}-VpcId'
```

2. Import in stack B with **`Fn::ImportValue`** (see `intrinsic-functions.md`) [2].

**Constraint:** You **cannot delete** the exporting stack while another stack imports its export — remove dependent stacks first [2].

---

## Conditions

**Conditions** are named booleans used to include/exclude resources, properties, or outputs [3].

### Defining Conditions

Built from:

- `Fn::Equals`, `Fn::Not`, `Fn::And`, `Fn::Or`
- `Fn::If` for inline selection
- References to other conditions, parameters, mappings [3]

### Using Conditions

- `Condition: MyCondition` on a **Resource** or **Output**
- Inside properties via `Fn::If`
- `AWS::NoValue` with `Fn::If` to **omit** optional properties [3][4]

### Common Patterns

- **Environment**: `Prod` vs `Dev` resources (e.g. extra monitoring in prod).
- **Region**: feature available only in some Regions.
- **Parameter-driven**: `CreateBucket: true/false`.

---

## References

- [Mappings][1]
- [Outputs][2]
- [Conditions][3]
- [Fn::If][4]

[1]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/mappings-section-structure.html
[2]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/outputs-section-structure.html
[3]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/conditions-section-structure.html
[4]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-if.html
