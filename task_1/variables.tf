variable "zone" {
  type    = string
  default = "ru-central1-a"
}

variable "network_name" {
  type    = string
  default = "tf-code-server-network"
}

variable "subnet_name" {
  type    = string
  default = "tf-code-server-subnet"
}

variable "vm_name" {
  type    = string
  default = "tf-code-server-vm"
}

variable "vm_user" {
  type    = string
  default = "yc-user"
}

variable "ssh_public_key_path" {
  type = string
}