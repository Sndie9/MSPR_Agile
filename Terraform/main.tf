terraform {
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.0"
    }
  }
}

provider "vsphere" {
  user                 = "administrator@vsphere.local"
  password             = "rootEpsi10!"
  vsphere_server       = "192.168.52.129" # Adresse IP de ton vCenter
  allow_unverified_ssl = true
}

# ============================
# DATA SOURCES
# ============================

# Récupération du datacenter
data "vsphere_datacenter" "dc" {
  name = "Datacenter"
}

# Récupération du datastore
data "vsphere_datastore" "datastore" {
  name          = "data_1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Récupération du réseau
data "vsphere_network" "network" {
  name          = "VM Network"
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Récupération de l'hôte ESXi (pas de cluster)
data "vsphere_host" "host" {
  name          = "192.168.52.128"  # Adresse IP de ton hôte ESXi
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Récupération du pool de ressources par défaut
data "vsphere_resource_pool" "pool" {
  name          = "Resources"
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Récupération du template
data "vsphere_virtual_machine" "template" {
  name          = "terraform_temp"
  datacenter_id = data.vsphere_datacenter.dc.id
}

# ============================
# VM RESOURCE
# ============================

resource "vsphere_virtual_machine" "web" {
  name             = "test_terraform"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = 1
  memory   = 1024
  guest_id = "debian12_64Guest"

  # Empêche Terraform d’attendre une IP de la VM
  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout  = 0

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = "vmxnet3"
  }

  disk {
    label = "disk0"
    size  = 16
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = "test_terraform"
        domain    = "local"
      }

      network_interface {
        ipv4_address = "192.168.52.111"
        ipv4_netmask = 24
      }
    }
  }
}
