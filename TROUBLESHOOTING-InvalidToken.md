# Troubleshooting: InvalidIdentityToken Error

## Error Details
- `InvalidIdentityToken`: The OIDC token from Azure DevOps is invalid
- `InvalidClientTokenId`: AWS cannot validate the token

## Root Causes & Solutions

### 1. Check IAM Trust Policy Subject (sub) Claim

The `sub` claim format MUST match exactly:
```
sc://<ORG_NAME>/<PROJECT_NAME>/<SERVICE_CONNECTION_NAME>
```

**Get the exact values:**
1. Organization Name: From your ADO URL `https://dev.azure.com/<ORG_NAME>`
2. Project Name: Your ADO project name (case-sensitive)
3. Service Connection Name: Exact name from Project Settings → Service Connections

**Current trust policy uses:** `sc://2286671-POC/AWS-ADO/*`

**Verify your actual values match:**
- Organization: `2286671-POC`
- Project: `AWS-ADO`
- Service Connection: `aws-ado-sc-feb28`

If different, update trust policy to:
```json
"vstoken.dev.azure.com/<ORG_ID>:sub": "sc://2286671-POC/AWS-ADO/aws-ado-sc-feb28"
```

### 2. Verify OIDC Provider Configuration

**Check Organization ID:**
```bash
# Get from: https://dev.azure.com/2286671-POC/_settings/organizationOverview
```

**Verify OIDC Provider exists:**
```bash
aws iam list-open-id-connect-providers
```

Should show: `arn:aws:iam::<ACCOUNT>:oidc-provider/vstoken.dev.azure.com/<ORG_ID>`

### 3. Check Trust Policy Audience (aud)

Remove or verify the `aud` condition. Try this trust policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<AWS_ACCOUNT_ID>:oidc-provider/vstoken.dev.azure.com/<ORG_ID>"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "vstoken.dev.azure.com/<ORG_ID>:sub": "sc://2286671-POC/AWS-ADO/aws-ado-sc-feb28"
        }
      }
    }
  ]
}
```

### 4. Verify Service Connection Configuration

In ADO Project Settings → Service Connections → `aws-ado-sc-feb28`:

- **Authentication:** OpenID Connect
- **AWS Account ID:** Your 12-digit account ID
- **Role ARN:** `arn:aws:iam::<ACCOUNT>:role/ado-oidc-terraform-role`
- **Role Session Name:** Any value (e.g., `ADO-Session`)

### 5. Debug Steps

**Step 1: Get Organization ID**
```bash
# Navigate to: https://dev.azure.com/2286671-POC/_settings/organizationOverview
# Copy the Organization ID (GUID format)
```

**Step 2: Update Trust Policy**
```bash
# Replace <ORG_ID> with actual Organization ID
aws iam update-assume-role-policy \
  --role-name ado-oidc-terraform-role \
  --policy-document file://iam-trust-policy-fixed.json
```

**Step 3: Verify Trust Policy**
```bash
aws iam get-role --role-name ado-oidc-terraform-role \
  --query 'Role.AssumeRolePolicyDocument'
```

**Step 4: Test in ADO**
- Go to Service Connection
- Click "Verify"
- Check error details

## Quick Fix

1. Get your ADO Organization ID (GUID)
2. Update `iam-trust-policy.json` with correct Organization ID
3. Change `sub` from wildcard to exact: `sc://2286671-POC/AWS-ADO/aws-ado-sc-feb28`
4. Apply updated trust policy to IAM role
5. Test service connection again
