# Setup IAM Roles for Kubernetes Service Accounts
# https://www.terraform.io/docs/providers/aws/r/eks_cluster.html#enabling-iam-roles-for-service-accounts
# https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts-technical-overview.html
data "aws_iam_policy_document" "service_account_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = join(":", [replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", ""), "sub"])
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks_oidc.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_openid_connect_provider" "eks_oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = []
  url             = aws_eks_cluster.eks_cluster.identity.0.oidc.0.issuer
}

# cert-manager and ExternalDNS
resource "aws_iam_role" "eks_external_dns_role" {
  name = join("-", [var.prefix, "eks-external-dns"])
  tags = var.tags

  assume_role_policy = data.aws_iam_policy_document.service_account_assume_role_policy.json
}

# ***** This policy attachment is dependent on an existing policy in the account. *****
resource "aws_iam_role_policy_attachment" "eks_external_dns_role-external-dns-route53-policy" {
  policy_arn = "arn:aws:iam::458527324684:policy/external-dns-route53-policy"
  role       = aws_iam_role.eks_external_dns_role.name
}

# Vault
resource "aws_iam_role" "eks_vault_unseal_role" {
  name = join("-", [var.prefix, "eks-vault-unseal"])
  tags = var.tags

  assume_role_policy = data.aws_iam_policy_document.service_account_assume_role_policy.json
}

resource "aws_iam_role_policy" "vault_kms_unseal" {
  name   = join("-", [var.prefix, "eks-vault-unseal"])
  role   = aws_iam_role.eks_vault_unseal_role.id
  policy = jsonencode({
    Statement = [{
      Actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:DescribeKey",
      ]
      Effect = "Allow"
      Resources = "*"
    }]
    Version = "2012-10-17"
  })
}