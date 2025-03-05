# Diet Tracker Terraform Deployment

This project deploys a Diet Tracking Application backend using AWS Lambda, DynamoDB, API Gateway, and IAM roles. Terraform provisions all required resources, and deployment/teardown are managed through a Makefile.

## Prerequisites

- **Terraform** (v0.12+ recommended)
- **AWS CLI** configured with credentials that have the necessary permissions.
- **zip** utility installed (used to package the Lambda function).

## Required IAM Permissions

> **NOTE:** This is not complete. Use AdminAccess in the meantime.

Ensure that your AWS credentials include permissions similar to the following policy. This policy allows creation of DynamoDB tables, IAM roles/policies, and API Gateway resources:

``json
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
``

*Note:* For development or testing, you might temporarily use an account with AdministratorAccess. For production, apply the least-privilege principle.

## Deployment

The deployment is managed by a Makefile that integrates the steps to package the Lambda function, initialize Terraform, create a plan, and apply the changes.

### To Deploy Resources

Run the following command from the project root (you can specify a custom namespace if desired):

``bash
make deploy NAMESPACE=mycustomnamespace
``

## Destroying Resources

To tear down all resources created by this deployment, use the following command:

``bash
make destroy NAMESPACE=mycustomnamespace
``

This command will remove all deployed AWS resources managed by Terraform. **Caution:** Ensure you want to delete these resources as this action cannot be undone.

## Post-Deployment Verification

After a successful deployment, verify that the resources are properly set up by:
- Checking the AWS Lambda console for the deployed function.
- Confirming that DynamoDB tables (DietGoals, MealLogs, ValidUsers) are created.
- Verifying the API Gateway endpoints using tools such as Postman or cURL.
- Reviewing CloudWatch logs for any errors or execution details of the Lambda function.

## Updating the Lambda Function

To update the Lambda function code:
1. Modify the `lambda_function.py` file as needed.
2. Redeploy the changes with:
   
   ``bash
   make deploy NAMESPACE=mycustomnamespace
   ``

## Adding a user
After deploying, you can add users to the application.
1. Request or assign a passphrase from user
2. Submit passphrase to the user database
   
   ``bash
   ./generated_resources/add_valid_user.sh "<passphrase>"
   ``
3. Send instructions in 'new_user_instructions.txt' and 'openapi.yaml' to new user.

## Troubleshooting

- **Terraform Plan Fails:** Verify that your AWS CLI credentials are correctly configured and that you have sufficient IAM permissions.
- **Resource Conflicts:** If you encounter issues with resource names (e.g., duplicates), consider using a unique namespace.
- **Lambda Deployment Errors:** Check CloudWatch logs for detailed error messages regarding the Lambda function.
- **API Gateway Issues:** Ensure the integration between API Gateway and Lambda is correctly configured and that permissions (via `aws_lambda_permission`) are set.

## Contributing

Contributions are welcome. Please fork this repository and submit pull requests with a clear description of your changes. For significant modifications, consider opening an issue first to discuss your ideas.

## License

This project is licensed under the MIT License. See the [`LICENSE`](`LICENSE`) file for details.

## Contact

For further questions or support, please open an issue in this repository or contact the project maintainers.

---

This document provides an overview of setting up and managing the Diet Tracker backend infrastructure. For advanced troubleshooting and additional configurations, refer to the official AWS and Terraform documentation.
