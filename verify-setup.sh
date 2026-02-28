#!/bin/bash

# Verification script for ADO-AWS OIDC setup

ADO_ORG_ID="<YOUR_ADO_ORG_ID>"
IAM_ROLE_NAME="ADO-OIDC-Role"

echo "=== Verifying OIDC Provider ==="
aws iam list-open-id-connect-providers | grep ${ADO_ORG_ID}

echo -e "\n=== Verifying IAM Role ==="
aws iam get-role --role-name ${IAM_ROLE_NAME} --query 'Role.Arn'

echo -e "\n=== Checking Trust Policy ==="
aws iam get-role --role-name ${IAM_ROLE_NAME} --query 'Role.AssumeRolePolicyDocument'

echo -e "\n=== Checking Attached Policies ==="
aws iam list-attached-role-policies --role-name ${IAM_ROLE_NAME}
