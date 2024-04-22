data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "create_ebs_volume_snapshot" {
  statement {
    effect    = "Allow"
    sid       = "CreateEBSVolumeSnapshot"
    actions   = ["ec2:*"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "create_ebs_volume_iam_role_policy_lambda" {
  name   = "create_ebs_volume"
  role   = aws_iam_role.iam_for_lambda.id
  policy = data.aws_iam_policy_document.create_ebs_volume_snapshot.json
}

# data "archive_file" "zip_the_python_code" {
#   type        = "zip"
#   source_file = "${path.module}/App/ebssnapshot.py"
#   output_path = "${path.module}/App/ebssnapshot.zip"
# }

resource "aws_lambda_function" "cron_lambda_2" {
  function_name = "cron_lambda_2"
  # filename      = "${path.module}/App/ebssnapshot.zip"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "ebssnopshot.lambda_handler"
  s3_bucket     = var.s3_bucket
  s3_key        = var.s3_key
  runtime = "python3.10"

  tags = merge({
    Name = "${var.env}-lf"
  }, local.common_tags)
}


# Create an EventBridge rule and Event Target to trigger Lambda Function
resource "aws_cloudwatch_event_rule" "cron_job_2" {
  name                = "EbsSnopShot"
  description         = "EbsSnopShot"
  schedule_expression = "cron(0/5 * * * ? *)"
  event_pattern = jsonencode({
    detail-type = [
      "My Lambda Function"
    ]
  })

  tags = merge({
    Name = "${var.env}-eb_rule"
  }, local.common_tags)
}

resource "aws_cloudwatch_event_target" "lambda_2" {
  rule      = aws_cloudwatch_event_rule.cron_job_2.name
  target_id = "SendToLambdaFunction"
  arn       = aws_lambda_function.cron_lambda_2.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cron_lambda_2.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cron_job_2.arn
}