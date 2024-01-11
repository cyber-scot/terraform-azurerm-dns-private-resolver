```hcl
resource "azurerm_private_dns_resolver" "resolver" {
  name                = var.name
  resource_group_name = var.rg_name
  location            = var.location
  virtual_network_id  = var.vnet_id
  tags                = var.tags
}

resource "azurerm_private_dns_resolver_outbound_endpoint" "outbound_endpoint" {
  name                    = var.outbound_endpoint_name != null ? var.outbound_endpoint_name : "${var.name}-outbound-ep"
  private_dns_resolver_id = azurerm_private_dns_resolver.resolver.id
  location                = azurerm_private_dns_resolver.resolver.location
  subnet_id               = var.outbound_endpoint_subnet_id
  tags                    = azurerm_private_dns_resolver.resolver.tags
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "inbound_endpoint" {
  name                    = var.inbound_endpoint_name != null ? var.inbound_endpoint_name : "${var.name}-inbound-ep"
  private_dns_resolver_id = azurerm_private_dns_resolver.resolver.id
  location                = azurerm_private_dns_resolver.resolver.location
  tags                    = azurerm_private_dns_resolver.resolver.tags

  dynamic "ip_configurations" {
    for_each = var.inbound_endpoint_ip_configurations
    content {
      private_ip_address_allocation = ip_configurations.value.private_ip_address_allocation
      subnet_id                     = ip_configurations.value.subnet_id
    }
  }
}

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "ruleset" {
  for_each                                   = { for k, v in var.dns_forwarding_rulesets : k => v if v.create_ruleset == true }
  name                                       = each.value.name
  resource_group_name                        = azurerm_private_dns_resolver.resolver.resource_group_name
  location                                   = azurerm_private_dns_resolver.resolver.location
  private_dns_resolver_outbound_endpoint_ids = concat([azurerm_private_dns_resolver_outbound_endpoint.outbound_endpoint.id], each.value.outbound_endpoint_ids)
  tags                                       = azurerm_private_dns_resolver.resolver.tags
}

locals {
  all_rules = toset(flatten([
    for ruleset_key, ruleset_value in var.dns_forwarding_rulesets : [
      for rule in ruleset_value.rules : {
        ruleset_key = ruleset_key
        rule        = rule
      }
    ]
  ]))
}


resource "azurerm_private_dns_resolver_forwarding_rule" "rules" {
  for_each                  = { for k, v in local.all_rules : k => v if v.rule.create_ruleset == true }
  name                      = each.value.name
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.ruleset[each.key].id
  domain_name               = each.value.domain_name
  enabled                   = each.value.enabled
  metadata                  = merge(var.tags, each.value.metadata)

  dynamic "target_dns_servers" {
    for_each = each.value.target_dns_servers
    content {
      ip_address = target_dns_servers.value.ip_address
      port       = target_dns_servers.value.port
    }
  }
}

resource "azurerm_private_dns_resolver_virtual_network_link" "vnet_link" {
  for_each                  = { for k, v in var.dns_forwarding_rulesets : k => v if v.create_ruleset == true }
  name                      = each.value.vnet_link_name != null ? each.value.vnet_link_name : "${each.value.name}-vnet-link"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.ruleset[each.key].id
  virtual_network_id        = each.value.vnet_id
  metadata                  = merge(var.tags, each.value.metadata)
}
```
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_private_dns_resolver.resolver](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver) | resource |
| [azurerm_private_dns_resolver_dns_forwarding_ruleset.ruleset](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver_dns_forwarding_ruleset) | resource |
| [azurerm_private_dns_resolver_forwarding_rule.rules](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver_forwarding_rule) | resource |
| [azurerm_private_dns_resolver_inbound_endpoint.inbound_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver_inbound_endpoint) | resource |
| [azurerm_private_dns_resolver_outbound_endpoint.outbound_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver_outbound_endpoint) | resource |
| [azurerm_private_dns_resolver_virtual_network_link.vnet_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver_virtual_network_link) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_description"></a> [description](#input\_description) | The description attached to AVNM | `string` | `null` | no |
| <a name="input_dns_forwarding_rulesets"></a> [dns\_forwarding\_rulesets](#input\_dns\_forwarding\_rulesets) | The list of DNS forwarding rulesets | <pre>list(object(<br>    {<br>      create_ruleset        = optional(bool, true)<br>      create_rules          = optional(bool, true)<br>      name                  = string<br>      forwarding_servers    = list(string)<br>      outbound_endpoint_ids = optional(list(string))<br>      vnet_link_name        = optional(string)<br>      vnet_id               = optional(string)<br>      metadata              = optional(map(string))<br>      rules = optional(list(object({<br>        name        = string<br>        domain_name = string<br>        enabled     = optional(bool, true)<br>        metadata    = optional(map(string))<br>        target_dns_servers = list(object({<br>          ip_address = optional(string)<br>          port       = optional(number)<br>        }))<br>        forwarding_port     = optional(number)<br>        forwarding_protocol = optional(string, "TCP")<br>        metadata            = optional(map(string))<br>      })))<br>  }))</pre> | `[]` | no |
| <a name="input_inbound_endpoint_ip_configurations"></a> [inbound\_endpoint\_ip\_configurations](#input\_inbound\_endpoint\_ip\_configurations) | The list of inbound endpoint ip configurations | <pre>list(object(<br>    {<br>      private_ip_address_allocation = optional(string, "Dynamic")<br>      subnet_id                     = string<br>  }))</pre> | n/a | yes |
| <a name="input_inbound_endpoint_name"></a> [inbound\_endpoint\_name](#input\_inbound\_endpoint\_name) | The inbound endpoint name, if you want to set it | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | The location where resources will be created. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of the AVNM instance | `string` | n/a | yes |
| <a name="input_outbound_endpoint_name"></a> [outbound\_endpoint\_name](#input\_outbound\_endpoint\_name) | The outbound endpoint name, if you want to set it | `string` | `null` | no |
| <a name="input_outbound_endpoint_subnet_id"></a> [outbound\_endpoint\_subnet\_id](#input\_outbound\_endpoint\_subnet\_id) | The ID of the subnet to be associated with the outbound endpoint | `string` | n/a | yes |
| <a name="input_rg_name"></a> [rg\_name](#input\_rg\_name) | The name of the resource group. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources. | `map(string)` | n/a | yes |
| <a name="input_vnet_id"></a> [vnet\_id](#input\_vnet\_id) | The ID of the VNet to be associated with the private resolver | `string` | n/a | yes |

## Outputs

No outputs.
