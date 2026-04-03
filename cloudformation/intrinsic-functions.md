# AWS CloudFormation — Intrinsic Functions

**Intrinsic functions** are built-in operations you use inside templates to join strings, look up maps, import exports, build lists, and branch on conditions [1].

---

## Exam “Must Know” Core

| Function | Typical use |
|----------|-------------|
| `Ref` (`!Ref`) | Parameter value; resource physical ID (type-dependent) [2] |
| `Fn::GetAtt` (`!GetAtt`) | Resource attributes (subnet AZ, bucket domain name, …) [3] |
| `Fn::FindInMap` (`!FindInMap`) | Mappings lookups [4] |
| `Fn::ImportValue` | Import `Export` from another stack [5] |
| `Fn::Base64` (`!Base64`) | Encode UserData / small blobs [6] |
| `Fn::Join` (`!Join`) | Build strings from lists [7] |
| `Fn::Sub` (`!Sub`) | String interpolation with `${Var}` or `Fn::Sub` list form [8] |
| `Fn::Select` (`!Select`) | Pick index from a list [9] |
| Condition helpers | `Fn::Equals`, `Fn::Not`, `Fn::And`, `Fn::Or`, `Fn::If` [10] |

---

## `Fn::Ref` / `!Ref`

- **Parameter** → parameter value [2].
- **Resource** → resource-specific return (often physical id; consult resource docs) [2].

```yaml
ImageId: !Ref AmiParameter
SubnetId: !Ref MySubnet
```

---

## `Fn::GetAtt` / `!GetAtt`

Returns a **named attribute** from a resource [3].

```yaml
!GetAtt MyInstance.AvailabilityZone
```

Always check the resource’s **Return values** in the CloudFormation docs [3].

---

## `Fn::FindInMap` / `!FindInMap`

```yaml
ImageId: !FindInMap [RegionMap, !Ref 'AWS::Region', HVM64]
```

---

## `Fn::ImportValue`

Imports a value exported by **Outputs → Export** in another stack [5].

```yaml
VpcId: !ImportValue network-VpcId
```

---

## `Fn::Base64` / `!Base64`

Often used with **EC2 UserData** (plain text must be base64 for the API; CloudFormation can encode for you) [6].

---

## `Fn::Join` / `!Join`

```yaml
!Join [ '', [ 'arn:aws:s3:::', !Ref MyBucket ] ]
```

---

## `Fn::Sub` / `!Sub`

**String interpolation:**

```yaml
Name: !Sub '${AWS::StackName}-app'
```

**With a map** (safer for literal `${}` in policies):

```yaml
Fn::Sub:
  - 'arn:aws:s3:::${Bucket}'
  - Bucket: !Ref LogsBucket
```

---

## `Fn::Select` / `!Select`

Pick an element from a **list** (often paired with `Fn::GetAZs`, `Fn::Split`, or parameters of type `CommaDelimitedList`) [9].

---

## `Fn::GetAZs`

Returns AZ names for a Region (commonly `''` for current Region) — useful for spreading subnets [11].

---

## `Fn::Split`

Split a string into a list (e.g. parse a parameter) [12].

---

## `Fn::Cidr`

Generate CIDR blocks from a network base (VPC subnet planning) [13].

---

## `Fn::Transform` / `Fn::ForEach` / `Fn::Length` / `Fn::ToJsonString`

- **`Fn::Transform`**: macro/template fragment transforms (advanced) [14].
- **`Fn::ForEach`**: expand a collection into repeated template fragments; requires the **`AWS::LanguageExtensions`** transform in the same template [15][18].
- **`Fn::Length`**: list length — also delivered via **`AWS::LanguageExtensions`** (declare `Transform: AWS::LanguageExtensions`) [16][18].
- **`Fn::ToJsonString`**: serialize objects to JSON strings — also part of **`AWS::LanguageExtensions`** [17][18].

Use these when the exam or real templates call for dynamic repetition or JSON-in-string patterns.

---

## Condition Functions

Used under `Conditions:` [10]:

- `Fn::Equals`
- `Fn::Not`
- `Fn::And`
- `Fn::Or`
- `Fn::If` (also used inline in properties)

---

## Full Reference

The authoritative list and parameters for every function live in the **Intrinsic function reference** [1].

---

## References

- [Intrinsic function reference][1]
- [Ref][2]
- [Fn::GetAtt][3]
- [Fn::FindInMap][4]
- [Fn::ImportValue][5]
- [Fn::Base64][6]
- [Fn::Join][7]
- [Fn::Sub][8]
- [Fn::Select][9]
- [Conditions][10]
- [Fn::GetAZs][11]
- [Fn::Split][12]
- [Fn::Cidr][13]
- [Fn::Transform][14]
- [Fn::ForEach][15]
- [Fn::Length][16]
- [Fn::ToJsonString][17]
- [AWS::LanguageExtensions transform][18]

[1]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference.html
[2]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-ref.html
[3]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-getatt.html
[4]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-findinmap.html
[5]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-importvalue.html
[6]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-base64.html
[7]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-join.html
[8]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-sub.html
[9]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-select.html
[10]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-conditions.html
[11]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-getavailabilityzones.html
[12]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-split.html
[13]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-cidr.html
[14]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-transform.html
[15]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-foreach.html
[16]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-length.html
[17]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-ToJsonString.html
[18]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/transform-aws-languageextensions.html
