terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  # Terraform will automatically pick up your Azure CLI login 
  # or Service Principal details from the environment.
}

# 1. Create a Resource Group for everything
resource "azurerm_resource_group" "main" {
  name     = "rg-devsecops-prod"
  location = "East US" # You can change this to your preferred region
}

# 2. Create the Azure Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  name                = "acrshrinet82prod" # Must be globally unique
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  admin_enabled       = false # STRICT: We use Azure AD/Entra ID for access, not admin keys
}

# 3. Create the AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-devsecops-prod"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "aksdevsecops"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2s_v3"
  }

  # STRICT: Use System-Assigned Managed Identity, no Service Principals
  identity {
    type = "SystemAssigned"
  }

  # MANDATORY for 2026 Zero-Trust
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # Enable Azure AD integration for K8s RBAC
  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# 4. Create the Azure Key Vault with RBAC enabled
resource "azurerm_key_vault" "vault" {
  name                      = "kvshrinet82prod" # Must be unique (3-24 chars)
  location                  = azurerm_resource_group.main.location
  resource_group_name       = azurerm_resource_group.main.name
  tenant_id                 = "0cd5a9c5-e95c-49b1-aa42-e56c1fdfeab9"
  sku_name                  = "standard"
  enable_rbac_authorization = true  # STRICT: No more legacy Access Policies
  purge_protection_enabled  = false # Set to true for actual production
}

# 5. Role Assignment: Allow AKS to pull images from ACR
resource "azurerm_role_assignment" "acrpull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}
