# Use the mlflow module to create an mlflow deployment
module "mlflow" {
  source = "../modules/mlflow-module"

  count = var.enable_experiment_tracker_mlflow ? 1 : 0

  # Run only after the eks cluster, cert-manager and nginx-ingress are set up
  depends_on = [
    aws_eks_cluster.cluster,
    null_resource.configure-local-kubectl,
    module.cert-manager,
    module.nginx-ingress,
    aws_s3_bucket.mlflow-bucket
  ]

  # Details about the mlflow deployment
  chart_version           = local.mlflow.chart_version
  image_version           = local.mlflow.image_version
  htpasswd                = "${var.mlflow-username}:${htpasswd_password.hash.apr1}"
  ingress_host            = "${local.mlflow.ingress_host_prefix}.${module.nginx-ingress[0].ingress-ip-address-aws}.nip.io"
  artifact_Proxied_Access = local.mlflow.artifact_Proxied_Access
  artifact_S3             = local.mlflow.artifact_S3
  artifact_S3_Bucket      = aws_s3_bucket.mlflow-bucket[0].bucket
}

resource "htpasswd_password" "hash" {
  password = var.mlflow-password
}

resource "random_string" "mlflow_bucket_suffix" {
  length  = 6
  special = false
  upper   = false
}

# Create s3 bucket for mlflow
resource "aws_s3_bucket" "mlflow-bucket" {
  count         = var.enable_experiment_tracker_mlflow ? 1 : 0
  bucket        = var.mlflow_bucket
  force_destroy = true

  tags = merge(local.common_tags, var.additional_tags)
}

# Block public access to the bucket
resource "aws_s3_bucket_public_access_block" "mlflow" {
  count  = var.enable_experiment_tracker_mlflow ? 1 : 0
  bucket = aws_s3_bucket.mlflow-bucket[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account_mlflow" {
  count  = var.enable_experiment_tracker_mlflow ? 1 : 0
  bucket = aws_s3_bucket.mlflow-bucket[0].id
  policy = data.aws_iam_policy_document.allow_access_from_another_account_mlflow[0].json
}

data "aws_iam_policy_document" "allow_access_from_another_account_mlflow" {
  count = var.enable_experiment_tracker_mlflow ? 1 : 0
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.ng[0].arn]
    }
    actions = [
      "s3:*",
    ]
    resources = [
      aws_s3_bucket.mlflow-bucket[0].arn,
      "${aws_s3_bucket.mlflow-bucket[0].arn}/*",
    ]
  }
}

# Allow the mlflow kubernetes SA to assume the IAM role
resource "null_resource" "mlflow-iam-access" {

  count = var.enable_experiment_tracker_mlflow ? 1 : 0

  provisioner "local-exec" {
    command = "kubectl annotate serviceaccount -n mlflow mlflow-tracking eks.amazonaws.com/role-arn=${aws_iam_role.ng[0].arn}"
  }

  depends_on = [
    module.mlflow,
  ]
}