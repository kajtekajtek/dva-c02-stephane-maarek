# AWS CloudFormation — Parameters

**Parameters** are inputs to a template. They let you reuse one template across environments (dev/prod), accounts, or teams without editing resource blocks every time [1].

---

## When to Use a Parameter

**Rule of thumb:** If a value might change between deployments or is unknown until deploy time, consider a **Parameter** instead of hardcoding [2].

Examples: instance type, CIDR, environment name, AMI id (sometimes better as **SSM Parameter** type), feature flags.

---

## How Parameters Flow

```text
Template + Parameter values → Stack create/update → Properties reference parameters via Ref
```

You can supply values in the console, CLI, or CI/CD [1].

---

## Parameter Properties (Common)

| Property | Purpose |
|----------|---------|
| `Type` | Data type (see below) [1] |
| `Default` | Used if caller omits the parameter [1] |
| `AllowedValues` | Enum list [1] |
| `AllowedPattern` | Regex constraint (strings) [1] |
| `ConstraintDescription` | Human text shown on validation failure [1] |
| `Description` | Help text [1] |
| `MinLength` / `MaxLength` | String length [1] |
| `MinValue` / `MaxValue` | Number bounds [1] |
| `NoEcho` | Mask in console/API (passwords) [1] |

---

## Parameter Types (High Level)

| Type | Notes |
|------|------|
| `String` | Text [1] |
| `Number` | Numeric [1] |
| `CommaDelimitedList` | Comma-separated strings [1] |
| `List<Number>` | List of numbers [1] |
| AWS-specific types | e.g. `AWS::EC2::VPC::Id` — validates against account [1] |
| `List<AWS::...>` | List of AWS-specific values [1] |
| `AWS::SSM::Parameter::Value<String>` (and similar) | Pull default from SSM Parameter Store [1] |

See the official **Parameters** section for the full type list and edge cases [1].

---

## Referencing a Parameter

- **`Fn::Ref`** with the **parameter logical name** returns the parameter value [3].
- YAML shorthand: **`!Ref ParamName`**

`Ref` is overloaded: on **parameters** it returns the value; on **resources** it returns resource-specific identifiers (often physical ID) [3].

---

## Pseudo Parameters (Built-in)

These are available in **every** template without declaring them under `Parameters:` [4].

| Pseudo parameter | Example meaning |
|------------------|-----------------|
| `AWS::AccountId` | Current account ID [4] |
| `AWS::Region` | Region where stack runs [4] |
| `AWS::StackId` | Stack ARN/ID [4] |
| `AWS::StackName` | Stack name [4] |
| `AWS::NotificationARNs` | SNS ARNs for stack notifications [4] |
| `AWS::NoValue` | Omits optional properties when used with `Fn::If` [4] |

---

## Parameters vs Mappings

| Use | Parameters | Mappings |
|-----|------------|----------|
| User-specific or deploy-time unknown | Yes | No |
| Fixed lookup tables (Region → AMI) | Awkward | Yes |
| Validation (AllowedValues, AWS types) | Strong | N/A |

See `mappings-outputs-conditions.md` for **Mappings** [1].

---

## References

- [Parameters section][1]
- [Fn::Ref][2]
- [Pseudo parameters][3]

[1]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/parameters-section-structure.html
[2]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-ref.html
[3]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html
