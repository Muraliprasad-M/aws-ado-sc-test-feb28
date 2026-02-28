# ADO → AWS OIDC Bundle

Contents:
- `azure-pipelines.yml` — Pipeline running on self-hosted agent `self-managed-ado-agent`, uses service connection `aws-ado-sc-feb28` and validates OIDC by calling STS.
- `iam-trust-policy.json` — Recommended trust (Option B): strict `aud`, flexible `sub` scoped to project: `sc://2286671-POC/AWS-ADO/*`.
- `terraform-iam-role.tf` — Optional Terraform to stand up the OIDC provider + role with the same trust.

Steps:
1. Import `iam-trust-policy.json` into your role `ado-oidc-terraform-role` (or apply the Terraform).
2. Ensure AWS Toolkit for Azure DevOps is installed and `aws-ado-sc-feb28` has **Use OIDC** enabled.
3. Commit `azure-pipelines.yml` to your repo and run it on your self-hosted agent.
