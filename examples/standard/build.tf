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
        }
      ]
    }
  ]
}





