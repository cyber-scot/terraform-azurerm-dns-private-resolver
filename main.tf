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
