data "aws_iam_policy_document" "frontend_bucket" {
  statement {
    sid = "AllowCloudFrontServicePrincipal"

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.frontend.arn}/*"
    ]

    principals {
      type = "Service"

      identifiers = [
        "cloudfront.amazonaws.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"

      values = [
        aws_cloudfront_distribution.frontend.arn
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = data.aws_iam_policy_document.frontend_bucket.json
}

resource "aws_iam_role_policy" "ecs_execution_secrets" {
  name = "${local.resource_prefix}-ecs-execution-secrets"
  role = aws_iam_role.ecs_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = [
        data.terraform_remote_state.persistent.outputs.rds_secret_arn,
        data.terraform_remote_state.persistent.outputs.jwt_secret_arn
      ]
    }]
  })
}