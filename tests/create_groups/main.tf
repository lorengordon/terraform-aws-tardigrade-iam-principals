provider aws {
  region = "us-east-1"
}

module "create_groups" {
  source = "../../modules/groups/"
  providers = {
    aws = aws
  }

  policy_arns = local.policy_arns
  groups      = [for group in local.groups : merge(local.group_base, group)]

  template_paths = ["${path.module}/../templates/"]
  template_vars = {
    "account_id" = data.aws_caller_identity.current.account_id
    "partition"  = data.aws_partition.current.partition
    "region"     = data.aws_region.current.name
  }
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "terraform_remote_state" "prereq" {
  backend = "local"
  config = {
    path = "prereq/terraform.tfstate"
  }
}

locals {
  test_id = length(data.terraform_remote_state.prereq.outputs) > 0 ? data.terraform_remote_state.prereq.outputs.random_string.result : ""

  policy_arns = length(data.terraform_remote_state.prereq.outputs) > 0 ? [for policy in data.terraform_remote_state.prereq.outputs.policies : policy.arn] : []

  inline_policies = [
    {
      name     = "tardigrade-alpha-${local.test_id}"
      template = "policies/template.json"
    },
    {
      name     = "tardigrade-beta-${local.test_id}"
      template = "policies/template.json"
    },
  ]

  group_base = {
    inline_policies = []
    path            = null
    policy_arns     = []
    user_names      = []
  }

  groups = [
    {
      name            = "tardigrade-group-alpha-${local.test_id}"
      policy_arns     = local.policy_arns
      inline_policies = local.inline_policies
      path            = "/tardigrade/alpha/"
    },
    {
      name            = "tardigrade-group-beta-${local.test_id}"
      policy_arns     = local.policy_arns
      inline_policies = local.inline_policies
    },
    {
      name        = "tardigrade-group-chi-${local.test_id}"
      policy_arns = local.policy_arns
    },
    {
      name            = "tardigrade-group-delta-${local.test_id}"
      inline_policies = local.inline_policies
    },
    {
      name = "tardigrade-group-epsilon-${local.test_id}"
    },
  ]
}

output "create_groups" {
  value = module.create_groups
}
