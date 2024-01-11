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
