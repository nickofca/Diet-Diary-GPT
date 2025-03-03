# Diet Tracker Terraform Deployment

This project deploys a Diet Tracking Application backend using AWS Lambda, DynamoDB, API Gateway, and IAM roles. Terraform provisions all required resources, and deployment/teardown are managed through a Makefile.

## Directory Structure

~~~text
.
├── Makefile
├── lambda_function.py
├── README.md
└── tf
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
~~~

## Prerequisites

- **Terraform** (v0.12+ recommended)
- **AWS CLI** configured with credentials that have the necessary permissions.
- **zip** utility installed (used to package the Lambda function).

## Required IAM Permissions

Ensure that your AWS credentials include permissions similar to the following policy. This policy allows creation of DynamoDB tables, IAM roles/policies, and API Gateway resources:

~~~json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:CreateTable",
                "dynamodb:DeleteTable",
                "dynamodb:DescribeTable",
                "dynamodb:UpdateTable",
                "dynamodb:PutItem",
                "dynamodb:GetItem",
                "dynamodb:Query",
                "dynamodb:TagResource",
                "dynamodb:DescribeContinuousBackups",
                "dynamodb:DescribeTimeToLive",
                "dynamodb:ListTagsOfResource"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateRole",
                "iam:GetRole",
                "iam:ListRolePolicies",
                "iam:ListAttachedRolePolicies",
                "iam:ListInstanceProfilesForRole",
                "iam:PutRolePolicy",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:PassRole",
                "iam:DeleteRole",
                "iam:CreatePolicy",
                "iam:GetPolicy",
                "iam:GetPolicyVersion",
                "iam:ListPolicyVersions",
                "iam:DeletePolicy"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "apigateway:POST",
                "apigateway:GET",
                "apigateway:PUT",
                "apigateway:DELETE",
                "apigateway:PATCH"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "lambda:CreateFunction",
                "lambda:UpdateFunctionCode",
                "lambda:UpdateFunctionConfiguration",
                "lambda:DeleteFunction",
                "lambda:GetFunction",
                "lambda:GetFunctionConfiguration",
                "lambda:ListVersionsByFunction",
                "lambda:GetFunctionCodeSigningConfig",
                "lambda:AddPermission",
                "lambda:GetPolicy",
                "lambda:RemovePermission"
            ],
            "Resource": "*"
        }
    ]
}
~~~

*Note:* For development or testing, you might temporarily use an account with AdministratorAccess. For production, apply the least-privilege principle.

## Deployment

The deployment is managed by a Makefile that integrates the steps to package the Lambda function, initialize Terraform, create a plan, and apply the changes.

### To Deploy Resources

Run the following command from the project root (you can specify a custom namespace if desired):

```bash
make deploy NAMESPACE=mycustomnamespace