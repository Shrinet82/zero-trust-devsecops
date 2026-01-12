variable "pat" {
  description = "Personal Access Token for Azure DevOps"
  type        = string
  sensitive   = true
}

variable "org_service_url" {
  description = "Azure DevOps Organization URL"
  type        = string
  default     = "https://dev.azure.com/madlunatic779"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-devsecops"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "snet-agents"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "pip" {
  name                = "pip-agent-vm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-agent-vm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_linux_virtual_machine" "agent_vm" {
  name                = "vm-devsecops-agent"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
              #!/bin/bash
              # Install Docker
              apt-get update
              apt-get install -y docker.io
              systemctl enable docker
              systemctl start docker

              # Create agent directory
              mkdir /myagent && cd /myagent
              
              # Download Agent (version 3.246.0)
              wget https://vstsagentpackage.azureedge.net/agent/3.246.0/vsts-agent-linux-x64-3.246.0.tar.gz
              tar zxvf vsts-agent-linux-x64-3.246.0.tar.gz

              # Allow agent to run as root (for simplicity in demo) or create user
              export AGENT_ALLOW_RUNASROOT="1"

              # Configure Agent
              ./config.sh --unattended \
                --url "${var.org_service_url}" \
                --auth pat \
                --token "${var.pat}" \
                --pool Default \
                --agent "AzureVM-Agent" \
                --acceptTeeEula

              # Install and Start Service
              ./svc.sh install
              ./svc.sh start
              EOF
  )
}
