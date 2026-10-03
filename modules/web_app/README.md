# web_app

Load-balanced web tier: an internet-facing Application Load Balancer in the public subnets and an Auto Scaling Group of Ubuntu 24.04 instances running Nginx in the private subnets, with CPU target-tracking and rolling instance refresh.

## Usage

```hcl
module "web_app" {
  source = "../../modules/web_app"

  environment        = "dev"
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids

  instance_type    = "t3.micro"
  min_size         = 1
  desired_capacity = 1
  max_size         = 2
}
```

The private subnets need outbound Internet access (a NAT Gateway) so instances can install packages and reach Systems Manager.

## Design notes

- **Network path:** the ALB accepts HTTP on port 80 from anywhere and can only send traffic to the instance security group; instances accept port 80 only from the ALB security group and allow outbound 80/443.
- **No SSH:** there is no key pair and no port 22. The instance role has only `AmazonSSMManagedInstanceCore`; connect with `aws ssm start-session`.
- **Instance hardening:** IMDSv2 required with hop limit 1, encrypted gp3 root volume.
- **Self-healing:** the ASG uses ELB health checks, so an instance whose Nginx stops answering is replaced. Changes to the launch template trigger a rolling instance refresh.
- **Capacity check:** the plan fails unless `min_size <= desired_capacity <= max_size`.
- **HTTP only:** there is no certificate in scope; the Checkov exceptions are justified inline in [`alb.tf`](alb.tf).

## Tests

[`tests/web_app.tftest.hcl`](tests/web_app.tftest.hcl) runs against a mocked AWS provider: `terraform test` from this directory, or `make test` from the repository root.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.7.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | ~> 5.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_autoscaling_group.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_autoscaling_policy.cpu_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy) | resource |
| [aws_iam_instance_profile.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ssm_core](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_launch_template.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_security_group.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.alb_to_app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.app_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_egress_rule.app_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.alb_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.app_from_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_ami.ubuntu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_default_tags.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/default_tags) | data source |
| [aws_iam_policy_document.ec2_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| environment | Environment name (dev, staging, prod). Used in resource names. | `string` | n/a | yes |
| private\_subnet\_ids | Private subnet IDs where the Auto Scaling Group launches instances. | `list(string)` | n/a | yes |
| public\_subnet\_ids | Public subnet IDs for the Application Load Balancer (at least two AZs). | `list(string)` | n/a | yes |
| vpc\_id | ID of the VPC that hosts the load balancer and instances. | `string` | n/a | yes |
| cpu\_target\_percent | Average CPU utilization the target tracking policy keeps the group at. | `number` | `60` | no |
| desired\_capacity | Initial number of instances in the Auto Scaling Group. | `number` | `1` | no |
| enable\_deletion\_protection | Prevent the load balancer from being deleted while this is true. | `bool` | `false` | no |
| enable\_detailed\_monitoring | Enable 1-minute CloudWatch metrics on instances (billed separately). | `bool` | `false` | no |
| instance\_type | EC2 instance type for the application instances. | `string` | `"t3.micro"` | no |
| max\_size | Maximum number of instances in the Auto Scaling Group. | `number` | `2` | no |
| min\_size | Minimum number of instances in the Auto Scaling Group. | `number` | `1` | no |
| root\_volume\_size | Root EBS volume size in GiB. | `number` | `8` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| alb\_dns\_name | Public DNS name of the Application Load Balancer. |
| app\_security\_group\_id | Security group ID of the application instances. |
| app\_url | HTTP URL of the application. |
| autoscaling\_group\_name | Name of the Auto Scaling Group. |
| iam\_role\_name | IAM role attached to the instances, for attaching extra policies. |
<!-- END_TF_DOCS -->
