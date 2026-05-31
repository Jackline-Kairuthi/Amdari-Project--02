###############################################
# WAFv2 WEB ACL
###############################################
resource "aws_wafv2_web_acl" "sentinelpay_waf" {
  name        = "sentinelpay-waf"
  description = "WAF for SentinelPay ALB"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "sentinelpay-waf"
    sampled_requests_enabled   = true
  }

  ###############################################
  # AWS MANAGED RULES
  ###############################################

  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "common-rules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "known-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "sqli-rules"
      sampled_requests_enabled   = true
    }
  }

  ###############################################
  # CUSTOM RATE LIMIT RULE
  ###############################################
  rule {
    name     = "RateLimitPerIP"
    priority = 10

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-limit"
      sampled_requests_enabled   = true
    }
  }
}

###############################################
# ASSOCIATE WAF WITH ALB (CORRECT)
###############################################
resource "aws_wafv2_web_acl_association" "sentinelpay_alb_assoc" {
  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.sentinelpay_waf.arn
}

###############################################
# OUTPUTS
###############################################
output "waf_web_acl_arn" {
  value = aws_wafv2_web_acl.sentinelpay_waf.arn
}

output "waf_association_id" {
  value = aws_wafv2_web_acl_association.sentinelpay_alb_assoc.id
}

