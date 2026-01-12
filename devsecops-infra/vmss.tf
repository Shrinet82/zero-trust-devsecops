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

resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = "vmss-devsecops-agents"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard_D2s_v3"
  instances           = 1 # Start with 1, let ADO scale
  admin_username      = "adminuser"

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "nic-vmss"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.subnet.id
    }
  }

  custom_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update
              # Install Docker
              apt-get install -y docker.io ca-certificates curl apt-transport-https lsb-release gnupg
              systemctl enable docker
              systemctl start docker
              chmod 666 /var/run/docker.sock
              
              # Install Azure CLI
              curl -sL https://aka.ms/InstallAzureCLIDeb | bash
              
              # Install Kubelogin (Python Direct Download for Reliability)
              python3 -c "import urllib.request, zipfile, os, stat, shutil; url = 'https://github.com/Azure/kubelogin/releases/download/v0.0.32/kubelogin-linux-amd64.zip'; urllib.request.urlretrieve(url, 'kubelogin.zip'); zipfile.ZipFile('kubelogin.zip', 'r').extractall('k_tmp'); shutil.move('k_tmp/bin/linux_amd64/kubelogin', '/usr/bin/kubelogin'); os.chmod('/usr/bin/kubelogin', 0o755)"
              
              # FIX: Symlink Node24 to Node20 (Workaround for ADO Agent Version Mismatch)
              # This ensures new agents can run tasks requiring Node 24
              ln -sf /agent/externals/node20_1 /agent/externals/node24
              EOF
  )

  # REQUIRED for Azure DevOps VMSS Agents
  upgrade_mode = "Manual"
  overprovision = false

  lifecycle {
    ignore_changes = [instances] # Prevent Terraform from resetting ADO auto-scaling
  }
}
