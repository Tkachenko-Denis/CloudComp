terraform {
  required_version = ">= 1.0.0"

  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  zone = var.zone
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2404-lts"
}

resource "yandex_vpc_network" "this" {
  name = var.network_name
}

resource "yandex_vpc_subnet" "this" {
  name           = var.subnet_name
  zone           = var.zone
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = ["10.10.10.0/24"]
}

resource "yandex_vpc_security_group" "this" {
  name       = "${var.vm_name}-sg"
  network_id = yandex_vpc_network.this.id

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_compute_instance" "this" {
  name        = var.vm_name
  zone        = var.zone
  platform_id = "standard-v2"

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 5
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 13
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.this.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.this.id]
  }

  metadata = {
    user-data = templatefile("${path.module}/cloud-init.yaml", {
      username = var.vm_user
      ssh_key  = trimspace(file(var.ssh_public_key_path))
    })
  }
}

output "external_ip" {
  value = yandex_compute_instance.this.network_interface[0].nat_ip_address
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/id_ed25519 ${var.vm_user}@${yandex_compute_instance.this.network_interface[0].nat_ip_address}"
}

output "code_server_tunnel" {
  value = "ssh -N -L 8080:127.0.0.1:8080 -i ~/.ssh/id_ed25519 ${var.vm_user}@${yandex_compute_instance.this.network_interface[0].nat_ip_address}"
}
