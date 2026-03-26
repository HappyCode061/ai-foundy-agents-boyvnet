############################################################
# CORE
############################################################

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "ai_account_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

############################################################
# PROJECTS OBJECT
############################################################

variable "projects" {
  description = "AI Foundry projects configuration"

  type = map(object({
    name       = string
    model = optional(object({
      name     = string
      version  = string
      sku      = string
      capacity = number
    }))

    search = optional(object({
      subscription_name = string
      resource_group    = string
      resource_name     = string
      connection_name   = string
    }))

    cosmos = optional(object({
      subscription_name = string
      resource_group    = string
      resource_name     = string
      connection_name   = string
    }))

    storage = optional(object({
      subscription_name = string
      resource_group    = string
      resource_name     = string
      connection_name   = string
    }))

    openai = optional(object({
      subscription_name = string
      resource_group    = string
      resource_name     = string
      connection_name   = string
    }))
  }))
}