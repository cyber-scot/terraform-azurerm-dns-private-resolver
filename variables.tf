variable "description" {
  description = "The description attached to AVNM"
  type        = string
  default     = null
}

variable "dns_forwarding_rulesets" {
  type = list(object(
    {
      create_ruleset        = optional(bool, true)
      create_rules          = optional(bool, true)
      name                  = string
      forwarding_servers    = list(string)
      outbound_endpoint_ids = optional(list(string))
      vnet_link_name        = optional(string)
      vnet_id               = optional(string)
      metadata              = optional(map(string))
      rules = optional(list(object({
        name        = string
        domain_name = string
        enabled     = optional(bool, true)
        metadata    = optional(map(string))
        target_dns_servers = list(object({
          ip_address = optional(string)
          port       = optional(number)
        }))
        forwarding_port     = optional(number)
        forwarding_protocol = optional(string, "TCP")
        metadata            = optional(map(string))
      })))
  }))
  description = "The list of DNS forwarding rulesets"
  default     = []
}

variable "inbound_endpoint_ip_configurations" {
  type = list(object(
    {
      private_ip_address_allocation = optional(string, "Dynamic")
      subnet_id                     = string
  }))
  description = "The list of inbound endpoint ip configurations"
}

variable "inbound_endpoint_name" {
  type        = string
  description = "The inbound endpoint name, if you want to set it"
  default     = null
}

variable "location" {
  description = "The location where resources will be created."
  type        = string
}

variable "name" {
  type        = string
  description = "The name of the AVNM instance"
}

variable "outbound_endpoint_name" {
  type        = string
  description = "The outbound endpoint name, if you want to set it"
  default     = null
}

variable "outbound_endpoint_subnet_id" {
  type        = string
  description = "The ID of the subnet to be associated with the outbound endpoint"
}

variable "rg_name" {
  description = "The name of the resource group."
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
}

variable "vnet_id" {
  type        = string
  description = "The ID of the VNet to be associated with the private resolver"
}
