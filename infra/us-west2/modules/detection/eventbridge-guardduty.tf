resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "guardduty-findings-to-sns"
  description = "Send GuardDuty findings to SNS"

  event_pattern = jsonencode({
    "source" : ["aws.guardduty"],
    "detail-type" : ["GuardDuty Finding"]
  })
}

resource "aws_cloudwatch_event_target" "guardduty_to_sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "sns"
  arn       = aws_sns_topic.security_alerts.arn
}

resource "aws_iam_role" "events_to_sns" {
  name = "events-to-sns-role"

  assume_role_policy = data.aws_iam_policy_document.events_assume.json
}

data "aws_iam_policy_document" "events_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "events_to_sns_policy" {
  role = aws_iam_role.events_to_sns.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["sns:Publish"],
      Resource = aws_sns_topic.security_alerts.arn
    }]
  })
}

resource "aws_cloudwatch_event_target" "guardduty_to_sns_with_role" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "sns"
  arn       = aws_sns_topic.security_alerts.arn
  role_arn  = aws_iam_role.events_to_sns.arn
}