# Identity and Access Management

IAM (Identity and Access Management) is a **global service**

## Users & Groups

- **Root account** created by default should not be used or shared
- **Users** are people within your organization and can be **grouped**
- **Groups** only contains users
- User don't have to belong to a group and can belong to multiple groups

## Permissions

### Policies

- Users & Groups can be assigned JSON-formatted **policies**
- These policies define the permissions of users
- **Least privilege principle** recommended to be applied

### Policies Structure

Policy consists of:
- **Version**: policy language version
- **Id**: an identifier for the policy *(optional)*
- **Statement**: one or more individual statements
    - **Sid**: an identifier for the statement *(optional)*
    - **Effect**: whether the statement allows or denies access
    - **Principal**: account/user/role to which this policy is applied to
    - **Action**: list of actions this policy allows or denies
    - **Resource**: list of resources to which the actions are applied to
    - **Condition**: conditions for when this policy is in effect *(optional)*

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ec2:Describe*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "elasticloadbalancing:Describe*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:ListMetrics",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:Describe*"
            ],
            "Resource": "*"
        }
    ]
}
```

- Example: AdministratorAccess permission policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}
```

