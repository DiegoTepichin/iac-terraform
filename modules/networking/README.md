# networking

VPC with one public and one private subnet per availability zone, an Internet Gateway, an optional single NAT Gateway for outbound traffic from the private subnets, and the default security group stripped of every rule.

## Usage

```hcl
module "networking" {
  source = "../../modules/networking"

  environment          = "dev"
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
}
```

## Design notes

- Subnets are created by index: `public_subnet_cidrs[i]` and `private_subnet_cidrs[i]` land in `availability_zones[i]`. A precondition on the VPC fails the plan if there are fewer zones than subnets.
- The NAT Gateway lives in the first public subnet, and a single private route table sends `0.0.0.0/0` through it for every private subnet. One NAT saves cost at the price of a single-AZ dependency for outbound traffic; see the root README for the trade-off.
- The default security group is managed with no rules, so nothing can accidentally rely on it.

## Tests

[`tests/networking.tftest.hcl`](tests/networking.tftest.hcl) runs against a mocked AWS provider: `terraform test` from this directory, or `make test` from the repository root.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.5.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
| ---- | ------- |
| aws | ~> 5.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_default_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_internet_gateway.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| availability\_zones | Availability zones, one per subnet pair. | `list(string)` | n/a | yes |
| environment | Environment name (dev, staging, prod). Used in resource names. | `string` | n/a | yes |
| private\_subnet\_cidrs | CIDR blocks of the private subnets, one per availability zone. | `list(string)` | n/a | yes |
| public\_subnet\_cidrs | CIDR blocks of the public subnets, one per availability zone. | `list(string)` | n/a | yes |
| enable\_nat\_gateway | Create a NAT Gateway so private subnets have outbound Internet access. | `bool` | `true` | no |
| vpc\_cidr | IPv4 CIDR block of the VPC. | `string` | `"10.0.0.0/16"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| nat\_gateway\_ips | Elastic IP addresses of the NAT Gateway (empty when disabled). |
| private\_subnet\_cidrs | CIDR blocks of the private subnets. |
| private\_subnet\_ids | IDs of the private subnets. |
| public\_subnet\_cidrs | CIDR blocks of the public subnets. |
| public\_subnet\_ids | IDs of the public subnets. |
| vpc\_cidr\_block | CIDR block of the VPC. |
| vpc\_id | ID of the VPC. |
<!-- END_TF_DOCS -->
