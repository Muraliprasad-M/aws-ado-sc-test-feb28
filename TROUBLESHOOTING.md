# ADO-AWS OIDC Service Connection Troubleshooting

## Common Issues & Solutions

### Issue: ADO service connection doesn't provide valid token

#### 1. Verify OIDC Provider Configuration in AWS

**Thumbprint Issue:**
- ADO OIDC thumbprint: `1B511ABEAD59C6CE207077C0BF0E0043B1382612`
- Ensure this exact thumbprint is used

**Provider URL:**
- `https://vstoken.dev.azure.com/<ORGANIZATION_ID>`
- Get Organization ID from: `https://dev.azure.com/<ORG_NAME>/_settings/organizationOverview`

#### 2. IAM Role Trust Policy

The trust policy MUST include:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<AWS_ACCOUNT_ID>:oidc-provider/vstoken.dev.azure.com/<ORGANIZATION_ID>"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "vstoken.dev.azure.com/<ORGANIZATION_ID>:sub": "sc://<ORG_NAME>/<PROJECT_NAME>/<SERVICE_CONNECTION_NAME>"
        }
      }
    }
  ]
}
```

#### 3. ADO Service Connection Configuration

**Service Connection Type:** AWS (OpenID Connect)

**Required Fields:**
- AWS Account ID: `<YOUR_AWS_ACCOUNT_ID>`
- Role ARN: `arn:aws:iam::<AWS_ACCOUNT_ID>:role/<ROLE_NAME>`
- Role Session Name: `ADO-Session` (or any name)
- Service Connection Name: Must match the `sub` claim in trust policy

#### 4. Common Mistakes

❌ **Wrong Audience in Trust Policy**
- Don't use `aud` condition unless ADO sends it
- Use `sub` condition instead

❌ **Incorrect Subject Format**
- Format: `sc://<ORG_NAME>/<PROJECT_NAME>/<SERVICE_CONNECTION_NAME>`
- Case-sensitive
- Must match exactly

❌ **Missing Permissions**
- IAM role needs permissions for actions you want to perform
- Add appropriate policies to the role

❌ **OIDC Provider Not Created**
- Must create OIDC provider before IAM role
- Provider URL must match exactly

#### 5. Validation Steps

1. **Check Organization ID:**
   ```
   https://dev.azure.com/<ORG_NAME>/_settings/organizationOverview
   ```

2. **Verify OIDC Provider exists:**
   ```bash
   aws iam list-open-id-connect-providers
   ```

3. **Check Role Trust Policy:**
   ```bash
   aws iam get-role --role-name <ROLE_NAME>
   ```

4. **Test Service Connection in ADO:**
   - Go to Project Settings → Service Connections
   - Click "Verify" on your connection
   - Check error message details

#### 6. Debug Token Claims

Add this to your pipeline to see what ADO sends:

```yaml
- task: AWSShellScript@1
  inputs:
    awsCredentials: '<SERVICE_CONNECTION_NAME>'
    regionName: 'us-east-1'
    scriptType: 'inline'
    inlineScript: |
      echo "Testing AWS credentials"
      aws sts get-caller-identity
```

## Quick Fix Checklist

- [ ] OIDC provider created with correct Organization ID
- [ ] Thumbprint is `1B511ABEAD59C6CE207077C0BF0E0043B1382612`
- [ ] IAM role trust policy uses correct `sub` format
- [ ] Service connection name matches trust policy
- [ ] IAM role has necessary permissions
- [ ] No typos in ARNs or names (case-sensitive)
