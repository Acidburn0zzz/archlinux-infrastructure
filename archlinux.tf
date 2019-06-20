terraform {
  backend "pg" {}
}

data "external" "hetzner_cloud_api_key" {
  program = ["${path.module}/misc/get_key.py", "misc/vault_hetzner.yml", "hetzner_cloud_api_key", "json"]
}

# Find the id using `hcloud image list`
variable "archlinux_image_id" {
  default = "2923545"
}

provider "hcloud" {
  token = "${data.external.hetzner_cloud_api_key.result.hetzner_cloud_api_key}"
}

resource "hcloud_rdns" "quassel" {
  server_id  = "${hcloud_server.quassel.id}"
  ip_address = "${hcloud_server.quassel.ipv4_address}"
  dns_ptr    = "quassel.archlinux.org"
}

resource "hcloud_server" "quassel" {
  name        = "quassel.archlinux.org"
  image       = "${var.archlinux_image_id}"
  server_type = "cx11"
}

resource "hcloud_rdns" "phrik" {
  server_id  = "${hcloud_server.phrik.id}"
  ip_address = "${hcloud_server.phrik.ipv4_address}"
  dns_ptr    = "phrik.archlinux.org"
}

resource "hcloud_server" "phrik" {
  name        = "phrik.archlinux.org"
  image       = "${var.archlinux_image_id}"
  server_type = "cx11"
}
