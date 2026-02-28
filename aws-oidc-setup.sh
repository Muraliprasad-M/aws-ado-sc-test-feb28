#!/bin/bash

# AWS OIDC Provider and IAM Role Setup for Azure DevOps
# Replace variables with your actual values

AWS_ACCOUNT_ID="<YOUR_AWS_ACCOUNT_ID>"
ADO_ORG_NAME="<YOUR_ADO_ORG_NAME>"
ADO_ORG_ID="<YOUR_ADO_ORG_ID>"
ADO_PROJECT_NAME="<YOUR_PROJECT_NAME>"
SERVICE_CONNECTION_NAME="<YOUR_SERVICE_CONNECTION_NAME>"
IAM_ROLE_NAME="ADO-OIDC-Role"
AWS_REGION="us-east-1"

# 1. Create OIDC Provider
echo "Creating OIDC Provider..."
aws iam create-open-id-connect-provider \
  --url "https://vstoken.dev.azure.com/${ADO_ORG_ID}" \
  --client-id-list "sts.amazonaws.com" \
  --thumbprint-list "1B511ABEAD59C6CE207077C0BF0E0043B1382612" \
  --region ${AWS_REGION}

# 2. Create Trust Policy
cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/vstoken.dev.azure.com/${ADO_ORG_ID}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "vstoken.dev.azure.com/${ADO_ORG_ID}:sub": "sc://${ADO_ORG_NAME}/${ADO_PROJECT_NAME}/${SERVICE_CONNECTION_NAME}"
        }
      }
    }
  ]
}
EOF

# 3. Create IAM Role
echo "Creating IAM Role..."
aws iam create-role \
  --role-name ${IAM_ROLE_NAME} \
  --assume-role-policy-document file://trust-policy.json \
  --region ${AWS_REGION}

# 4. Attach Policy (example: ReadOnlyAccess)
echo "Attaching policy to role..."
aws iam attach-role-policy \
  --role-name ${IAM_ROLE_NAME} \
  --policy-arn "arn:aws:iam::aws:policy/ReadOnlyAccess" \
  --region ${AWS_REGION}

echo "Setup complete!"
echo "Role ARN: arn:aws:iam::${AWS_ACCOUNT_ID}:role/${IAM_ROLE_NAME}"
