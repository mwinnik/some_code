# Salt-Master in AWS
This module manages salt-master instance (single master topology only) and all of its dependencies in AWS

## Prerequisites
- Vault server with appropriate salt-master approle
- The ssh `bootstrap` key for `baseline` AMI has been added to `ssh-agent`

## Example Usages
The example below provisions a salt-master EC2 instance with the following features:
* Use AWS DynamoDB table `My_SaltPillar` as salt pillar source 
* Use git filesever backend from `git@github.com:Spirent-CIP/my-saltfs.git` with `base` salt environment from `main` branch
* Use additional salt git pillar source from a subdirectory named `pillars` in the `base` salt environment
```hcl
module "my_salt_master" {
  source                 = "git@github.com:Spirent-Terraform-Modules/terraform-aws-salt-master.git"
  cert_alt_names         = "salt.spirent.dev"
  domain                 = "is.cal.aws.spirent.dev"
  environment            = "internal-service"
  environment_level      = "prod"
  environment_type       = "service"
  gitfs_pillar_root      = "pillars"
  gitfs_remote           = "git@github.com:Spirent-CIP/my-saltfs.git"
  gitfs_private_ssh_key  = data.vault_generic_secret.gitfs_login_credentials.data["ssh-private-key"]
  gitfs_public_ssh_key   = data.vault_generic_secret.gitfs_login_credentials.data["ssh-public-key"]
  instance_name          = "mysalt"
  pillar_table_name      = "My_SaltPillar"
  region                 = "us-west-2"
  reverse_zone_id        = "Z123456779ABCDEFGHIJK"
  site                   = "cal"
  short_region           = "usw2"
  subnet_id              = "subnet-0a1b2c3d4e5f6g"
  vault_github_pat_key   = "service-account/github.com/API/admin"
  vault_github_pat_field = "personal-access-token"
  vpc_id                 = "vpc-0a1b2c3d4e5f6g7h8"
  user_identity          = "songkamong"
  zone_id                = "Z987654321ABCDEFGHIJK"
}
```

The following example provisions a salt-master EC2 instance that uses default local file system as salt fileserver backend (`/srv/salt`) and pillar source (`/srv/pillar`)
```hcl
module "my_salt_master" {
  source               = "git@github.com:Spirent-Terraform-Modules/terraform-aws-salt-master.git"
  cert_alt_names       = "salt.spirent.dev"
  domain               = "is.cal.aws.spirent.dev"
  environment          = "internal-service"
  environment_level    = "prod"
  environment_type     = "service"
  instance_name        = "mysalt"
  region               = "us-west-2"
  reverse_zone_id      = "Z123456779ABCDEFGHIJK"
  site                 = "cal"
  short_region         = "usw2"
  subnet_id            = "subnet-0a1b2c3d4e5f6g"
  vpc_id               = "vpc-0a1b2c3d4e5f6g7h8"
  user_identity        = "songkamong"
  zone_id              = "Z987654321ABCDEFGHIJK"
}
```
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.14.4 |
| aws | >= 3.23.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.23.0 |
| template | n/a |
| vault | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| salt_master_dns | git@github.com:Spirent-Terraform-Modules/terraform-aws-r53-a-record.git?ref=v0.11 |  |
| salt_master_pillar_table | git@github.com:Spirent-Terraform-Modules/terraform-aws-dynamodb-table.git?ref=develop |  |

## Resources

| Name |
|------|
| [aws_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) |
| [aws_iam_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) |
| [aws_iam_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) |
| [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) |
| [aws_iam_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) |
| [aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) |
| [aws_network_interface](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) |
| [aws_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) |
| [aws_security_group_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) |
| [template_file](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) |
| [vault_approle_auth_backend_role_secret_id](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/approle_auth_backend_role_secret_id) |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| additional\_security\_group\_ids | Additional Security Group IDs to add to the instance | `list(string)` | `[]` | no |
| allowed\_salt\_inbound\_cidr\_blocks | A list of CIDR-formatted IP address ranges from which the EC2 Instances will allow connections to salt-master | `list(string)` | <pre>[<br>  "10.0.0.0/8"<br>]</pre> | no |
| allowed\_salt\_inbound\_security\_group\_ids | A list of security group IDs that will be allowed to connect to salt-master | `list(string)` | `[]` | no |
| allowed\_ssh\_inbound\_cidr\_blocks | A list of CIDR-formatted IP address ranges from which SSH will be allowed from | `list(string)` | <pre>[<br>  "10.0.0.0/8"<br>]</pre> | no |
| cert\_alt\_names | Specifies requested Subject Alternative Names, in a comma-delimited list. These can be host names or email addresses; they will be parsed into their respective fields. If any requested names do not match role policy, the entire request will be denied. | `string` | `""` | no |
| cert\_ip\_sans | Specifies requested IP Subject Alternative Names, in a comma-delimited list. | `string` | `""` | no |
| cert\_ttl | Specifies requested Time To Live. Cannot be greater than the role's max\_ttl value. If not provided, the role's ttl value will be used. Note that the role values default to system values if not explicitly set. | `string` | `"8760h"` | no |
| domain | Domain name | `string` | n/a | yes |
| environment | Name of Environment where the resources will reside | `string` | n/a | yes |
| environment\_level | Level of Environment | `string` | n/a | yes |
| environment\_type | Environment Type | `string` | n/a | yes |
| gitfs\_pillar\_root | The root directory for git salt pillars | `string` | `""` | no |
| gitfs\_private\_ssh\_key | Private ssh key to be used for authentication to 'gitfs\_remote' | `string` | `""` | no |
| gitfs\_public\_ssh\_key | Public ssh key to be used for authentication to 'gitfs\_remote' | `string` | `""` | no |
| gitfs\_remote | Git repo to be used as salt filesystem backend in ssh format | `string` | `""` | no |
| gitfs\_remote\_base\_branch | Git branch to be used as base environment for salt file system | `string` | `"main"` | no |
| instance\_name | Name of the instance | `string` | n/a | yes |
| instance\_root\_volume\_size | EC2 instance root volume size | `string` | `20` | no |
| instance\_root\_volume\_type | EC2 instance root volume type | `string` | `"standard"` | no |
| instance\_type | EC2 instance type for salt-master | `string` | `"t2.micro"` | no |
| pillar\_table\_name | Name of the AWS DynomoDB table that will be used as pillar source for this salt-master | `string` | `""` | no |
| region | Region name | `string` | `"us-west-2"` | no |
| reverse\_zone\_id | ID of private reverse zone for PTR record of instance | `string` | n/a | yes |
| salt\_environments | List of salt environments | `list(string)` | <pre>[<br>  "base"<br>]</pre> | no |
| salt\_publisher\_port | The port to use for salt publisher | `number` | `4505` | no |
| salt\_request\_port | The port to use for salt request | `number` | `4506` | no |
| salt\_ssh\_port | The port to use for ssh | `number` | `22` | no |
| short\_region | Abbreviated region name | `string` | `"usw2"` | no |
| site | Site designator. | `string` | n/a | yes |
| ssh\_key\_name | Name of bootstray key to use | `string` | `"bootstrap"` | no |
| subnet\_id | Subnet ID to use | `string` | n/a | yes |
| use\_validated | Whether or not to use a validated AMI to build the instance | `bool` | `false` | no |
| user\_identity | Name of user running terraform | `any` | n/a | yes |
| vault\_github\_pat\_field | Vault field name for personal access token key used for querying 'gitfs\_remote' on Github.com | `string` | `"personal-access-token"` | no |
| vault\_github\_pat\_key | Vault path to personal access token key used for querying 'gitfs\_remote' on Github.com | `string` | `""` | no |
| vpc\_id | Target VPC to put resources in | `string` | n/a | yes |
| zone\_id | ID of private zone to place R53 A record in | `string` | n/a | yes |


## Outputs

| Name | Description |
|------|-------------|
| salt\_master\_fqdn | FQDN of salt-master |
| salt\_master\_ip | Private IP of salt-master |
