```hcl
module "rg" {
  source = "cyber-scot/rg/azurerm"

  name     = "rg-${var.short}-${var.loc}-${var.env}-01"
  location = local.location
  tags     = local.tags
}

data "azurerm_subscription" "current" {}

module "network" {
  source = "cyber-scot/network/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  vnet_name          = "vnet-${var.short}-${var.loc}-${var.env}-01"
  vnet_location      = module.rg.rg_location
  vnet_address_space = ["10.0.0.0/16"]

  subnets = {
    "sn1-outbound-ep-${module.network.vnet_name}" = {
      address_prefixes = ["10.0.0.0/24"]
      delegation = [
        {
          type = "Microsoft.Network/dnsResolvers"
        },
      ]
    }
    "sn2-inbound-ep-${module.network.vnet_name}" = {
      address_prefixes = ["10.0.1.0/24"]
      delegation = [
        {
          type = "Microsoft.Network/dnsResolvers"
        },
      ]
    }
  }
}


module "resolver" {
  source = "../../"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  name                        = "resolver-${var.short}-${var.loc}-${var.env}-01"
  vnet_id                     = module.network.vnet_id
  outbound_endpoint_subnet_id = module.network.subnets_ids["sn1-outbound-ep-${module.network.vnet_name}"]
  inbound_endpoint_ip_configurations = [
    {
      subnet_id = module.network.subnets_ids["sn2-inbound-ep-${module.network.vnet_name}"]
    }
  ]

  dns_forwarding_rulesets = [
    {
      create_ruleset = true
      name           = "ruleset1"
      metadata       = { key = "value" }
      rules = [
        {
          name        = "rule1"
          domain_name = "cyber.scot"
          enabled     = true
          metadata    = { key = "value" }
          target_dns_servers = [
            {
              ip_address = "192.0.2.1"
              port       = 53
            }
          ]
        },
        {
          name        = "rule2"
          domain_name = "cyber.scot"
          enabled     = true
          metadata    = { key = "value" }
          target_dns_servers = [
            {
              ip_address = "192.0.5.1"
              port       = 53
            }
          ]
        }
      ]
    }
  ]
}





```
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.86.0 |
| <a name="provider_external"></a> [external](#provider\_external) | 2.3.2 |
| <a name="provider_http"></a> [http](#provider\_http) | 3.4.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_network"></a> [network](#module\_network) | cyber-scot/network/azurerm | n/a |
| <a name="module_resolver"></a> [resolver](#module\_resolver) | ../../ | n/a |
| <a name="module_rg"></a> [rg](#module\_rg) | cyber-scot/rg/azurerm | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |
| [external_external.detect_os](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [external_external.generate_timestamp](https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external) | data source |
| [http_http.client_ip](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_Regions"></a> [Regions](#input\_Regions) | Converts shorthand name to longhand name via lookup on map list | `map(string)` | <pre>{<br>  "eus": "East US",<br>  "euw": "West Europe",<br>  "uks": "UK South",<br>  "ukw": "UK West"<br>}</pre> | no |
| <a name="input_env"></a> [env](#input\_env) | The env variable, for example - prd for production. normally passed via TF\_VAR. | `string` | `"prd"` | no |
| <a name="input_loc"></a> [loc](#input\_loc) | The loc variable, for the shorthand location, e.g. uks for UK South.  Normally passed via TF\_VAR. | `string` | `"uks"` | no |
| <a name="input_short"></a> [short](#input\_short) | The shorthand name of to be used in the build, e.g. cscot for CyberScot.  Normally passed via TF\_VAR. | `string` | `"cscot"` | no |
| <a name="input_static_tags"></a> [static\_tags](#input\_static\_tags) | The tags variable | `map(string)` | <pre>{<br>  "Contact": "info@cyber.scot",<br>  "CostCentre": "671888",<br>  "ManagedBy": "Terraform"<br>}</pre> | no |

## Outputs

No outputs.
