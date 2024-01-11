output "dns_forwarding_ruleset_ids" {
  value       = { for k, v in azurerm_private_dns_resolver_dns_forwarding_ruleset.ruleset : k => v.id }
  description = "A map of DNS Forwarding Ruleset IDs, keyed by the ruleset name."
}

output "dns_forwarding_ruleset_names" {
  value       = { for k, v in azurerm_private_dns_resolver_dns_forwarding_ruleset.ruleset : k => v.name }
  description = "A map of DNS Forwarding Ruleset names, keyed by the ruleset name."
}

output "forwarding_rule_ids" {
  value       = { for k, v in azurerm_private_dns_resolver_forwarding_rule.rules : k => v.id }
  description = "A map of forwarding rule IDs for the DNS resolver, keyed by the rule name."
}

output "forwarding_rule_names" {
  value       = { for k, v in azurerm_private_dns_resolver_forwarding_rule.rules : k => v.name }
  description = "A map of forwarding rule names for the DNS resolver, keyed by the rule name."
}

output "inbound_endpoint_id" {
  value       = azurerm_private_dns_resolver_inbound_endpoint.inbound_endpoint.id
  description = "The ID of the inbound endpoint associated with the Azure Private DNS Resolver."
}

output "inbound_endpoint_name" {
  value       = azurerm_private_dns_resolver_inbound_endpoint.inbound_endpoint.name
  description = "The name of the inbound endpoint associated with the Azure Private DNS Resolver."
}

output "outbound_endpoint_id" {
  value       = azurerm_private_dns_resolver_outbound_endpoint.outbound_endpoint.id
  description = "The ID of the outbound endpoint associated with the Azure Private DNS Resolver."
}

output "outbound_endpoint_name" {
  value       = azurerm_private_dns_resolver_outbound_endpoint.outbound_endpoint.name
  description = "The name of the outbound endpoint associated with the Azure Private DNS Resolver."
}

output "private_dns_resolver_id" {
  value       = azurerm_private_dns_resolver.resolver.id
  description = "The ID of the Azure Private DNS Resolver."
}

output "private_dns_resolver_name" {
  value       = azurerm_private_dns_resolver.resolver.name
  description = "The name of the Azure Private DNS Resolver."
}

output "virtual_network_link_ids" {
  value       = { for k, v in azurerm_private_dns_resolver_virtual_network_link.vnet_link : k => v.id }
  description = "A map of Virtual Network Link IDs for the DNS resolver, keyed by the link name."
}

output "virtual_network_link_names" {
  value       = { for k, v in azurerm_private_dns_resolver_virtual_network_link.vnet_link : k => v.name }
  description = "A map of Virtual Network Link names for the DNS resolver, keyed by the link name."
}
