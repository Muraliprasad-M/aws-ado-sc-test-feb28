variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "ado_org_id" {
  description = "Azure DevOps Organization ID"
  type        = string
}

resource "aws_iam_openid_connect_provider" "ado_oidc" {
  url             = "https://vstoken.dev.azure.com/${var.ado_org_id}"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["1B511ABEAD59C6CE207077C0BF0E0043B1382612"]
}

resource "aws_iam_role" "ado_oidc_role" {
  name = "ado-oidc-terraform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/vstoken.dev.azure.com/${var.ado_org_id}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "vstoken.dev.azure.com/${var.ado_org_id}:aud" = "sts.amazonaws.com"
            "vstoken.dev.azure.com/${var.ado_org_id}:sub" = "sc://2286671-POC/AWS-ADO/*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ado_policy" {
  role       = aws_iam_role.ado_oidc_role.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

output "role_arn" {
  value = aws_iam_role.ado_oidc_role.arn
}
