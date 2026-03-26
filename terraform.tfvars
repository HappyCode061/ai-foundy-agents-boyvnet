resource_group_name = "rg-ai-foundry-10"
location            = "swedencentral"
ai_account_name     = "yogi0001122newaccount-10"
vnet_name = "vnet-ai-foundry-7-m9ym"
agent_subnet_name = "exiting-snet-ai-agent-8"
vnet_resource_group = "rg-ai-foundry-8"

projects = {
  project1 = {
    name       = "ai-project-6"
    # search = {
    #   subscription_name = "Azure subscription 1"
    #   resource_group    = "rg-ai-foundry-yogi"
    #   resource_name     = "yogi0001122search-12"
    #   connection_name   = "search-conn"
    # }

    # cosmos = {
    #   subscription_name = "Azure subscription 1"
    #   resource_group    = "rg-data"
    #   resource_name     = "yogi0001122cosmos1"
    #   connection_name   = "cosmos-conn"
    # }

    # storage = {
    #   subscription_name = "Azure subscription 1"
    #   resource_group    = "rg-ai-foundry-yogi"
    #   resource_name     = "yogistoargeaccount01"
    #   connection_name   = "storage-conn"
    # }

    # openai = {
    #   subscription_name = "Azure subscription 1"
    #   resource_group    = "rg-ai-foundry-1"
    #   resource_name     = "aifoundry-poc-00011223399"
    #   connection_name   = "openai-conn"
    # }
  }

  project2 = {
    name       = "ai-project-7"
  #   search = {
  #     subscription_name = "Azure subscription 1"
  #     resource_group    = "rg-ai-foundry-1"
  #     resource_name     = "yogi0001122search2"
  #     connection_name   = "search-conn-2"
  #   }

  #   cosmos = {
  #     subscription_name = "Azure subscription 1"
  #     resource_group    = "rg-ai-foundry-1"
  #     resource_name     = "yogi0001122cosmos2"
  #     connection_name   = "cosmos-conn-2"
  #   }

  #   storage = {
  #     subscription_name = "Azure subscription 1"
  #     resource_group    = "rg-ai-foundry-1"
  #     resource_name     = "yogistoargeaccount02"
  #     connection_name   = "storage-conn-2"
  #   }
  }
}

tags = {
  env   = "dev"
  owner = "ai-team"
}
