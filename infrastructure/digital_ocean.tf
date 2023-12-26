provider "digitalocean" {
  token = var.do_api_key_token
}

resource "digitalocean_droplet" "droplet" {
  image    = "ubuntu-23-10-x64"
  name     = "ubuntu-s-1vcpu-512mb-10gb-ams3-01"
  region   = local.do_region
  size     = "s-1vcpu-512mb-10gb"
  ssh_keys = [var.do_ssh_key_fingerprint]
  vpc_uuid = local.do_vpc_uuid
}

resource "digitalocean_project" "project" {
  name = "sermadrid"
  resources = [
    digitalocean_droplet.droplet.urn,
    digitalocean_domain.default.urn,
  ]
}

resource "digitalocean_domain" "default" {
  name = var.domain_name
}

resource "digitalocean_record" "www_record" {
  domain = digitalocean_domain.default.id
  type   = "A"
  name   = "www"
  value  = digitalocean_droplet.droplet.ipv4_address
}

resource "digitalocean_record" "apex_record" {
  domain = digitalocean_domain.default.id
  type   = "A"
  name   = "@"
  value  = digitalocean_droplet.droplet.ipv4_address
}
