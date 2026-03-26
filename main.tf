data "azurerm_subscriptions" "all" {}

locals {
  projects = {
    for k, v in var.projects : k => v
  }

  all_projects = azurerm_cognitive_account_project.projects

  subscription_name_to_id = {
    for s in data.azurerm_subscriptions.all.subscriptions :
    s.display_name => s.subscription_id
  }

  storage_info = {
    for k, v in var.projects :
    k => {
      resource_id = "/subscriptions/${local.subscription_name_to_id[v.storage.subscription_name]}/resourceGroups/${v.storage.resource_group}/providers/Microsoft.Storage/storageAccounts/${v.storage.resource_name}"
      blob_endpoint   = "https://${v.storage.resource_name}.blob.core.windows.net"
      connection_name = v.storage.connection_name
    }
    if try(v.storage, null) != null
  }

  openai_info = {
    for k, v in var.projects :
    k => {
      resource_id = "/subscriptions/${local.subscription_name_to_id[v.openai.subscription_name]}/resourceGroups/${v.openai.resource_group}/providers/Microsoft.CognitiveServices/accounts/${v.openai.resource_name}"
      connection_name = v.openai.connection_name
    }
    if try(v.openai, null) != null
  }

  search_info = {
    for k, v in var.projects :
    k => {
      resource_id = "/subscriptions/${local.subscription_name_to_id[v.search.subscription_name]}/resourceGroups/${v.search.resource_group}/providers/Microsoft.Search/searchServices/${v.search.resource_name}"
      endpoint        = "https://${v.search.resource_name}.search.windows.net"
      connection_name = v.search.connection_name
    }
    if try(v.search, null) != null
  }

  cosmos_info = {
    for k, v in var.projects :
    k => {
      resource_id = "/subscriptions/${local.subscription_name_to_id[v.cosmos.subscription_name]}/resourceGroups/${v.cosmos.resource_group}/providers/Microsoft.DocumentDB/databaseAccounts/${v.cosmos.resource_name}"

      endpoint        = "https://${v.cosmos.resource_name}.documents.azure.com:443/"
      connection_name = v.cosmos.connection_name
      rg_name = v.cosmos.resource_group
      account_name = v.cosmos.resource_name
    }
    if try(v.cosmos, null) != null
  }
}

############################################################
# RANDOM SUFFIX (FOR UNIQUE NAMING)
############################################################

resource "random_string" "net_suffix" {
  length  = 4
  upper   = false
  special = false
}

############################################################
# RESOURCE GROUP
############################################################

resource "azurerm_resource_group" "rg" {
  # provider = azurerm.ai
  name     = var.resource_group_name
  location = var.location
}

############################################################
# VIRTUAL NETWORK
############################################################

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-ai-foundry-7-${random_string.net_suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.10.0.0/16"]

  tags = var.tags
}

############################################################
# NETWORK SECURITY GROUP (BASIC)
############################################################

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-ai-foundry-${random_string.net_suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = var.tags
}

############################################################
# AGENT SUBNET (FOR AI FOUNDRY NETWORK INJECTION)
############################################################

resource "azurerm_subnet" "agent_subnet" {
  name                 = "snet-ai-agent-7"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]

  delegation {
    name = "agent-delegation"

    service_delegation {
      name = "Microsoft.App/environments"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

############################################################
# PRIVATE ENDPOINT SUBNET
############################################################

resource "azurerm_subnet" "private_endpoint_subnet" {
  name                 = "snet-private-endpoints"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.2.0/24"]
}

############################################################
# ASSOCIATE NSG TO SUBNETS
############################################################

resource "azurerm_subnet_network_security_group_association" "agent_nsg_assoc" {
  subnet_id                 = azurerm_subnet.agent_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_subnet_network_security_group_association" "pe_nsg_assoc" {
  subnet_id                 = azurerm_subnet.private_endpoint_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

############################################################
# AI FOUNDRY (WITH NETWORK INJECTION)
############################################################

resource "azurerm_cognitive_account" "ai_account" {
  name                = lower("${var.ai_account_name}-${random_string.net_suffix.result}")
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind     = "AIServices"
  sku_name = "S0"
  custom_subdomain_name      = lower("${var.ai_account_name}-${random_string.net_suffix.result}")
  project_management_enabled = true

  identity {
    type = "SystemAssigned"
  }

  public_network_access_enabled = false

  network_acls {
    default_action = "Allow"
  }
  network_injection {
    scenario  = "agent"
    subnet_id = azurerm_subnet.agent_subnet.id
  }
}

# resource "azapi_resource" "ai_account" {
#   type      = "Microsoft.CognitiveServices/accounts@2025-06-01"
#   name      = lower("${var.ai_account_name}-${random_string.net_suffix.result}")
#   location  = azurerm_resource_group.rg.location
#   parent_id = azurerm_resource_group.rg.id

#   schema_validation_enabled = false

#   body = {
#     kind = "AIServices"

#     sku = {
#       name = "S0"
#     }

#     identity = {
#       type = "SystemAssigned"
#     }

#     properties = {
#       ####################################################
#       # REQUIRED FOR AI FOUNDRY
#       ####################################################
#       customSubDomainName    = lower("${var.ai_account_name}-${random_string.net_suffix.result}")
#       allowProjectManagement = true

#       ####################################################
#       # SECURITY (LOCK DOWN PUBLIC ACCESS)
#       ####################################################
#       publicNetworkAccess = "Disabled"

#       networkAcls = {
#         defaultAction = "Allow"
#       }

#       ####################################################
#       # 🚀 NETWORK INJECTION (CORE PART)
#       ####################################################
#       networkInjections = [
#         {
#           scenario                   = "agent"
#           subnetArmId                = azurerm_subnet.agent_subnet.id
#           useMicrosoftManagedNetwork = false
#         }
#       ]
#     }
#   }
# }


############################################################
#  PROJECT (CREATED)
############################################################

resource "azurerm_cognitive_account_project" "projects" {
  for_each = var.projects
  # provider             = azurerm.ai
  name                 = each.value.name
  cognitive_account_id =azurerm_cognitive_account.ai_account.id
  location             = azurerm_resource_group.rg.location

  identity {
    type = "SystemAssigned"
  }

  # tags = merge(var.tags, { project_type = "default" })
}


############################################################
# NORMAL PROJECTS (CREATED AFTER DEFAULT)
############################################################

# resource "azurerm_cognitive_account_project" "normal" {
#   for_each = local.normal_projects

#   # provider             = azurerm.ai
#   name                 = each.value.name
#   cognitive_account_id =azurerm_cognitive_account.ai_account.id
#   location             = azurerm_resource_group.rg.location

#   identity {
#     type = "SystemAssigned"
#   }

#   tags = merge(var.tags, { project_type = "normal" })

#   depends_on = [
#     azurerm_cognitive_account_project.default
#   ]
# }


############################################################
# WAIT FOR IDENTITY PROPAGATION
############################################################

resource "time_sleep" "wait_identity" {
  depends_on = [
    azurerm_cognitive_account_project.projects
  ]
  create_duration = "60s"
}

############################################################
# RBAC ASSIGNMENTS (AFTER IDENTITY)
############################################################

resource "azurerm_role_assignment" "search_role" {
  for_each = local.search_info
  principal_id         = local.all_projects[each.key].identity[0].principal_id
  role_definition_name = "Search Service Contributor"
  scope                = each.value.resource_id
  depends_on = [time_sleep.wait_identity]
}

resource "azurerm_role_assignment" "storage_role" {
  for_each = local.storage_info
  principal_id         = local.all_projects[each.key].identity[0].principal_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = each.value.resource_id

  depends_on = [time_sleep.wait_identity]
}


############################################################
# COSMOS ROLE ASSIGNMENT
############################################################

resource "azurerm_cosmosdb_sql_role_definition" "threads_data_contributor" {
  for_each = local.cosmos_info

  name                = "threads-data-contributor-${each.key}"
  account_name        = each.value.account_name
  resource_group_name = each.value.rg_name
  assignable_scopes   = [each.value.resource_id]

  permissions {
    data_actions = [
      "Microsoft.DocumentDB/databaseAccounts/readMetadata",
      "Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*"
    ]
  }
}

resource "azurerm_cosmosdb_sql_role_assignment" "cosmos_role" {
  for_each = local.cosmos_info

  account_name        = each.value.account_name
  resource_group_name = each.value.rg_name
  role_definition_id  = azurerm_cosmosdb_sql_role_definition.threads_data_contributor[each.key].id
  principal_id        = local.all_projects[each.key].identity[0].principal_id
  scope               = each.value.resource_id

  depends_on = [time_sleep.wait_identity]
}

############################################################
# WAIT FOR RBAC
############################################################

resource "time_sleep" "wait_rbac" {
  depends_on = [
    azurerm_role_assignment.search_role,
    azurerm_role_assignment.storage_role,
    azurerm_cosmosdb_sql_role_assignment.cosmos_role
  ]
  create_duration = "90s"
}

############################################################
# CONNECTIONS (OPTIONAL PER PROJECT)
############################################################

############################################################
# CONNECTIONS - SEARCH
############################################################

resource "azapi_resource" "conn_search" {
  for_each = local.search_info
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name      = each.value.connection_name
  parent_id = local.all_projects[each.key].id
  schema_validation_enabled = false

  body = {
    properties = {
      category = "CognitiveSearch"
      target   = each.value.resource_id
      authType = "ProjectManagedIdentity"
    }
  }

  depends_on = [
    time_sleep.wait_identity,
    time_sleep.wait_rbac
  ]
}

############################################################
# CONNECTIONS - COSMOS
############################################################

resource "azapi_resource" "conn_cosmos" {
  for_each = local.cosmos_info
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name      = each.value.connection_name
  parent_id = local.all_projects[each.key].id
  schema_validation_enabled = false

  body = {
    properties = {
      category = "CosmosDb"
      target   = each.value.resource_id
      authType = "ProjectManagedIdentity"
    }
  }

  depends_on = [
    time_sleep.wait_identity,
    time_sleep.wait_rbac
  ]
}

############################################################
# CONNECTIONS - STORAGE
############################################################

resource "azapi_resource" "conn_storage" {
  for_each = local.storage_info
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name      = each.value.connection_name
  parent_id = local.all_projects[each.key].id
  schema_validation_enabled = false

  body = {
    properties = {
      category = "AzureStorageAccount"
      target   = each.value.blob_endpoint
      authType = "ProjectManagedIdentity"

      metadata = {
        ResourceId = each.value.resource_id
      }
    }
  }

  depends_on = [
    time_sleep.wait_identity,
    time_sleep.wait_rbac
  ]
}
############################################################
# CONNECTIONS - OPENAI
############################################################

resource "azapi_resource" "conn_openai" {
  for_each = local.openai_info
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name      = each.value.connection_name
  parent_id = local.all_projects[each.key].id
  schema_validation_enabled = false
  ignore_missing_property   = true

  body = {
    properties = {
      category = "AzureOpenAI"
      target   = each.value.resource_id
      authType = "ProjectManagedIdentity"

      metadata = {
        ApiType    = "Azure"
        ResourceId = each.value.resource_id
      }
    }
  }

  depends_on = [
    time_sleep.wait_identity,
    time_sleep.wait_rbac
  ]
}