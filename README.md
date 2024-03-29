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
      private_ip_allocation_method = ip_configurations.value.private_ip_allocation_method
      subnet_id                    = ip_configurations.value.subnet_id
    }
  }
}

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "ruleset" {
  for_each            = { for k, v in var.dns_forwarding_rulesets : k => v if v.create_ruleset == true }
  name                = each.value.name
  resource_group_name = azurerm_private_dns_resolver.resolver.resource_group_name
  location            = azurerm_private_dns_resolver.resolver.location
  private_dns_resolver_outbound_endpoint_ids = concat(
    [azurerm_private_dns_resolver_outbound_endpoint.outbound_endpoint.id],
    coalesce(each.value.outbound_endpoint_ids, [])
  )

  tags = azurerm_private_dns_resolver.resolver.tags
}

# This local value constructs a flattened map of all the rules from various DNS forwarding rulesets.
# It iterates over each ruleset defined in 'var.dns_forwarding_rulesets'. For each ruleset, it further iterates over each rule.
# In this nested iteration:
# - 'ruleset_key' represents the key of the current ruleset.
# - 'ruleset_value' is the value (object) of the current ruleset, which includes a list of rules.
# - 'idx' is the index of the current rule within its ruleset.
# - 'rule' is the current rule object.
#
# Each rule is mapped to a unique key that combines the 'ruleset_key' and the 'idx' (index of the rule) in the format: "ruleset_key-idx".
# This unique key ensures that each rule can be individually identified and accessed, which is particularly useful for resources that require a distinct identifier for each iteration.
#
# The inner 'for' loop creates a map for each ruleset, where each entry corresponds to a rule within that ruleset.
# The outer 'for' loop goes through each of these maps, and the 'merge' function with the splat operator '...' is used to merge all these individual maps into a single map.
#
# The resulting 'all_rules' map is a comprehensive collection of all rules across all the rulesets, with each rule being easily accessible via its unique key.
#
# The ellipsis (...) is used in conjunction with the 'merge' function.
# This is a key aspect of the splat syntax in Terraform and serves the following purposes:

# 1. Expanding Collections:
#    The ellipsis is used to expand a list of maps into individual map arguments.
#    This expansion is crucial because the 'merge' function is designed to accept multiple
#    map arguments separately, rather than a single list containing maps.

# 2. Flattening and Merging:
#    Each inner 'for' loop within the locals block generates a map, and these maps are
#    collected into a list. By using the ellipsis, the 'merge' function flattens this list
#    and merges all the individual maps into one comprehensive map. This results in a
#    single map that combines all entries from the original list of maps.

# 3. Dynamic Configuration:
#    The use of ellipsis is particularly beneficial in dynamic and complex configurations.
#    It allows for the combination of multiple similar or related items (like maps from each
#    ruleset and its rules) into a single entity without the need to manually specify each
#    map as a separate argument to the 'merge' function.
#

locals {
  all_rules = merge([
    for ruleset_key, ruleset_value in var.dns_forwarding_rulesets : {
      for idx, rule in ruleset_value.rules : "${ruleset_key}-${idx}" => {
        ruleset_key = ruleset_key
        rule        = rule
      }
    }
  ]...)
}

resource "azurerm_private_dns_resolver_forwarding_rule" "rules" {
  for_each                  = local.all_rules
  name                      = each.value.rule.name
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.ruleset[each.value.ruleset_key].id
  domain_name               = each.value.rule.domain_name
  enabled                   = each.value.rule.enabled
  metadata                  = merge(var.tags, each.value.rule.metadata)

  dynamic "target_dns_servers" {
    for_each = each.value.rule.target_dns_servers
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
  virtual_network_id        = var.vnet_id
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
| <a name="input_dns_forwarding_rulesets"></a> [dns\_forwarding\_rulesets](#input\_dns\_forwarding\_rulesets) | The list of DNS forwarding rulesets | <pre>list(object(<br>    {<br>      create_ruleset        = optional(bool, true)<br>      create_rules          = optional(bool, true)<br>      name                  = string<br>      outbound_endpoint_ids = optional(list(string))<br>      vnet_link_name        = optional(string)<br>      metadata              = optional(map(string))<br>      rules = optional(list(object({<br>        name        = string<br>        domain_name = string<br>        enabled     = optional(bool, true)<br>        metadata    = optional(map(string))<br>        target_dns_servers = list(object({<br>          ip_address = optional(string)<br>          port       = optional(number)<br>        }))<br>        forwarding_port     = optional(number)<br>        forwarding_protocol = optional(string, "TCP")<br>      })))<br>  }))</pre> | `[]` | no |
| <a name="input_inbound_endpoint_ip_configurations"></a> [inbound\_endpoint\_ip\_configurations](#input\_inbound\_endpoint\_ip\_configurations) | The list of inbound endpoint ip configurations | <pre>list(object(<br>    {<br>      private_ip_allocation_method = optional(string, "Dynamic")<br>      subnet_id                    = string<br>  }))</pre> | n/a | yes |
| <a name="input_inbound_endpoint_name"></a> [inbound\_endpoint\_name](#input\_inbound\_endpoint\_name) | The inbound endpoint name, if you want to set it | `string` | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | The location where resources will be created. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of the AVNM instance | `string` | n/a | yes |
| <a name="input_outbound_endpoint_name"></a> [outbound\_endpoint\_name](#input\_outbound\_endpoint\_name) | The outbound endpoint name, if you want to set it | `string` | `null` | no |
| <a name="input_outbound_endpoint_subnet_id"></a> [outbound\_endpoint\_subnet\_id](#input\_outbound\_endpoint\_subnet\_id) | The ID of the subnet to be associated with the outbound endpoint | `string` | n/a | yes |
| <a name="input_rg_name"></a> [rg\_name](#input\_rg\_name) | The name of the resource group. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources. | `map(string)` | n/a | yes |
| <a name="input_vnet_id"></a> [vnet\_id](#input\_vnet\_id) | The ID of the VNet to be associated with the private resolver | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dns_forwarding_ruleset_ids"></a> [dns\_forwarding\_ruleset\_ids](#output\_dns\_forwarding\_ruleset\_ids) | A map of DNS Forwarding Ruleset IDs, keyed by the ruleset name. |
| <a name="output_dns_forwarding_ruleset_names"></a> [dns\_forwarding\_ruleset\_names](#output\_dns\_forwarding\_ruleset\_names) | A map of DNS Forwarding Ruleset names, keyed by the ruleset name. |
| <a name="output_forwarding_rule_ids"></a> [forwarding\_rule\_ids](#output\_forwarding\_rule\_ids) | A map of forwarding rule IDs for the DNS resolver, keyed by the rule name. |
| <a name="output_forwarding_rule_names"></a> [forwarding\_rule\_names](#output\_forwarding\_rule\_names) | A map of forwarding rule names for the DNS resolver, keyed by the rule name. |
| <a name="output_inbound_endpoint_id"></a> [inbound\_endpoint\_id](#output\_inbound\_endpoint\_id) | The ID of the inbound endpoint associated with the Azure Private DNS Resolver. |
| <a name="output_inbound_endpoint_name"></a> [inbound\_endpoint\_name](#output\_inbound\_endpoint\_name) | The name of the inbound endpoint associated with the Azure Private DNS Resolver. |
| <a name="output_outbound_endpoint_id"></a> [outbound\_endpoint\_id](#output\_outbound\_endpoint\_id) | The ID of the outbound endpoint associated with the Azure Private DNS Resolver. |
| <a name="output_outbound_endpoint_name"></a> [outbound\_endpoint\_name](#output\_outbound\_endpoint\_name) | The name of the outbound endpoint associated with the Azure Private DNS Resolver. |
| <a name="output_private_dns_resolver_id"></a> [private\_dns\_resolver\_id](#output\_private\_dns\_resolver\_id) | The ID of the Azure Private DNS Resolver. |
| <a name="output_private_dns_resolver_name"></a> [private\_dns\_resolver\_name](#output\_private\_dns\_resolver\_name) | The name of the Azure Private DNS Resolver. |
| <a name="output_virtual_network_link_ids"></a> [virtual\_network\_link\_ids](#output\_virtual\_network\_link\_ids) | A map of Virtual Network Link IDs for the DNS resolver, keyed by the link name. |
| <a name="output_virtual_network_link_names"></a> [virtual\_network\_link\_names](#output\_virtual\_network\_link\_names) | A map of Virtual Network Link names for the DNS resolver, keyed by the link name. |
