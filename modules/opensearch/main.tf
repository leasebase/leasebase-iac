################################################################################
# OpenSearch Serverless Module - LeaseBase v2 (optional)
################################################################################

resource "aws_opensearchserverless_security_policy" "encryption" {
  count = var.enabled ? 1 : 0

  name = "${var.name_prefix}-enc"
  type = "encryption"
  policy = jsonencode({
    Rules = [
      {
        Resource     = ["collection/${var.name_prefix}-search"]
        ResourceType = "collection"
      }
    ]
    AWSOwnedKey = true
  })
}

resource "aws_opensearchserverless_security_policy" "network" {
  count = var.enabled ? 1 : 0

  name = "${var.name_prefix}-net"
  type = "network"
  policy = jsonencode([
    {
      Rules = [
        {
          Resource     = ["collection/${var.name_prefix}-search"]
          ResourceType = "collection"
        }
      ]
      AllowFromPublic = false
      SourceVPCEs     = []
    }
  ])
}

resource "aws_opensearchserverless_collection" "main" {
  count = var.enabled ? 1 : 0

  name = "${var.name_prefix}-search"
  type = "SEARCH"

  depends_on = [
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network,
  ]

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-search"
  })
}
