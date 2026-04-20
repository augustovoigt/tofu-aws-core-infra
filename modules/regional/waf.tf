# AWS WAF ACL

locals {
  default_waf = {
    waf_acl_name             = "${var.aws_region}-waf-acl"
    waf_acl_description      = "WAF ACL to protect public applications in ${var.aws_region} region"
    sampled_requests_enabled = true

    rules = [
      {
        name            = "AWS-AWSManagedRulesAnonymousIpList"
        priority        = 0
        vendor_name     = "AWS"
        rule_group_name = "AWSManagedRulesAnonymousIpList"
        metric_name     = "AWS-AWSManagedRulesAnonymousIpList"
      },
      {
        name            = "AWS-AWSManagedRulesAdminProtectionRuleSet"
        priority        = 1
        vendor_name     = "AWS"
        rule_group_name = "AWSManagedRulesAdminProtectionRuleSet"
        metric_name     = "AWS-AWSManagedRulesAdminProtectionRuleSet"
      },
      {
        name            = "AWS-AWSManagedRulesAmazonIpReputationList"
        priority        = 2
        vendor_name     = "AWS"
        rule_group_name = "AWSManagedRulesAmazonIpReputationList"
        metric_name     = "AWS-AWSManagedRulesAmazonIpReputationList"
      },
      {
        name            = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
        priority        = 3
        vendor_name     = "AWS"
        rule_group_name = "AWSManagedRulesKnownBadInputsRuleSet"
        metric_name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
      },
      {
        name            = "AWS-AWSManagedRulesLinuxRuleSet"
        priority        = 4
        vendor_name     = "AWS"
        rule_group_name = "AWSManagedRulesLinuxRuleSet"
        metric_name     = "AWS-AWSManagedRulesLinuxRuleSet"
      },
      {
        name            = "AWS-AWSManagedRulesCommonRuleSet"
        priority        = 5
        vendor_name     = "AWS"
        rule_group_name = "AWSManagedRulesCommonRuleSet"
        metric_name     = "AWS-AWSManagedRulesCommonRuleSet"
      },
      {
        name            = "AWS-AWSManagedRulesSQLiRuleSet"
        priority        = 6
        vendor_name     = "AWS"
        rule_group_name = "AWSManagedRulesSQLiRuleSet"
        metric_name     = "AWS-AWSManagedRulesSQLiRuleSet"
      }
    ]
  }

  waf = merge(local.default_waf, var.waf)
}

module "waf" {
  count                    = var.create_waf ? 1 : 0
  source                   = "git::https://github.com/augustovoigt/tofu-aws-modules.git//modules/aws/waf?ref=main"
  waf_acl_name             = local.waf.waf_acl_name
  waf_acl_description      = local.waf.waf_acl_description
  sampled_requests_enabled = local.waf.sampled_requests_enabled
  rules                    = local.waf.rules
}