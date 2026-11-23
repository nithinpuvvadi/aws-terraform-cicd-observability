
# ---------------------------------------------------------
# Current AWS account
# ---------------------------------------------------------

data "aws_caller_identity" "current" {}

# ---------------------------------------------------------
# GitHub Actions Terraform deployment role
# ---------------------------------------------------------

resource "aws_iam_role" "github_actions_terraform" {
  name               = "${var.project_name}-github-actions-terraform"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

# ---------------------------------------------------------
# S3 remote Terraform state access
# ---------------------------------------------------------

resource "aws_iam_policy" "github_actions_terraform_state" {
  name        = "${var.project_name}-github-actions-terraform-state"
  description = "Allow GitHub Actions to access the project's Terraform S3 state and lock file"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ListTerraformStateBucket"
        Effect = "Allow"

        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]

        Resource = "arn:aws:s3:::aws-terraform-cicd-observability-tfstate-470527513869"

        Condition = {
          StringLike = {
            "s3:prefix" = [
              "environments/dev",
              "environments/dev/*"
            ]
          }
        }
      },
      {
        Sid    = "AccessTerraformState"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]

        Resource = "arn:aws:s3:::aws-terraform-cicd-observability-tfstate-470527513869/environments/dev/terraform.tfstate"
      },
      {
        Sid    = "ManageTerraformStateLock"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]

        Resource = "arn:aws:s3:::aws-terraform-cicd-observability-tfstate-470527513869/environments/dev/terraform.tfstate.tflock"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_terraform_state" {
  role       = aws_iam_role.github_actions_terraform.name
  policy_arn = aws_iam_policy.github_actions_terraform_state.arn
}

# ---------------------------------------------------------
# AWS service permissions for the lab
# ---------------------------------------------------------

resource "aws_iam_role_policy_attachment" "github_actions_terraform_poweruser" {
  role       = aws_iam_role.github_actions_terraform.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# ---------------------------------------------------------
# Project-scoped IAM management permissions
# ---------------------------------------------------------

resource "aws_iam_policy" "github_actions_terraform_iam" {
  name        = "${var.project_name}-github-actions-terraform-iam"
  description = "Allow Terraform GitHub Actions to manage project-specific IAM resources"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ManageProjectRoles"
        Effect = "Allow"

        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:UpdateRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:ListRoleTags",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:PutRolePolicy",
          "iam:GetRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:ListRolePolicies"
        ]

        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*"
      },
      {
        Sid    = "ManageProjectPolicies"
        Effect = "Allow"

        Action = [
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:SetDefaultPolicyVersion",
          "iam:TagPolicy",
          "iam:UntagPolicy",
          "iam:ListPolicyVersions"
        ]

        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.project_name}-*"
      },
      {
        Sid    = "ManageProjectInstanceProfiles"
        Effect = "Allow"

        Action = [
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:TagInstanceProfile",
          "iam:UntagInstanceProfile"
        ]

        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${var.project_name}-*"
      },
      {
        Sid    = "PassProjectRolesToEC2"
        Effect = "Allow"

        Action = [
          "iam:PassRole"
        ]

        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-*"

        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ec2.amazonaws.com"
          }
        }
      },
      {
        Sid    = "ReadIAMResources"
        Effect = "Allow"

        Action = [
          "iam:ListRoles",
          "iam:ListPolicies",
          "iam:ListInstanceProfiles",
          "iam:ListInstanceProfilesForRole",
          "iam:ListOpenIDConnectProviders",
          "iam:GetOpenIDConnectProvider"
        ]

        Resource = "*"
      },
      {
        Sid    = "CreateRequiredServiceLinkedRoles"
        Effect = "Allow"

        Action = [
          "iam:CreateServiceLinkedRole"
        ]

        Resource = "*"

        Condition = {
          StringLike = {
            "iam:AWSServiceName" = [
              "autoscaling.amazonaws.com",
              "elasticloadbalancing.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_terraform_iam" {
  role       = aws_iam_role.github_actions_terraform.name
  policy_arn = aws_iam_policy.github_actions_terraform_iam.arn
}

# ---------------------------------------------------------
# Output
# ---------------------------------------------------------

output "github_actions_terraform_role_arn" {
  description = "IAM role ARN assumed by the Terraform GitHub Actions workflow"
  value       = aws_iam_role.github_actions_terraform.arn
}

