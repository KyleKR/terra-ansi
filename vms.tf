# Configure the IBM Cloud Provider
provider "ibm" {
  bluemix_api_key    = "${var.ibm_bmx_api_key}"
  softlayer_username = "${var.ibm_sl_username}"
  softlayer_api_key  = "${var.ibm_sl_api_key}"
}

# Create an SSH key. You can find the SSH key surfaces in the SoftLayer console under Devices > Manage > SSH Keys
resource "ibm_compute_ssh_key" "hyperledger_key" {
  label      = "hyperledger_key"
  public_key = "ssh-rsa put_your_public_ssh_key hyperledger_dwmeetup"
}

data "ibm_compute_image_template" "img_hyperledger_1" {
  name = "Hyperledger meetup 1"
}

data "ibm_dns_domain" "dw_domain" {
  name = "dwmeetup.arcy.me"
}

# Create a virtual server with the SSH key
resource "ibm_compute_vm_instance" "hyperledger_vm" {
  hostname          = "${format("vm%03d", count.index + 1)}"
  domain            = "dwmeetup.arcy.me"
  ssh_key_ids       = ["${ibm_compute_ssh_key.hyperledger_key.id}"]
  image_id          = "${data.ibm_compute_image_template.img_hyperledger_1.id}"
  datacenter        = "seo01"
  network_speed     = 100
  cores             = 2
  memory            = 4096
  tags = [
    "hyperledger",
    "dwmeetup"
  ]
  wait_time_minutes = 15
  count = "${var.vm_count}"
}

resource "ibm_dns_record" "www" {
  data = "${element(ibm_compute_vm_instance.hyperledger_vm.*.ipv4_address, count.index)}"
  domain_id = "${data.ibm_dns_domain.dw_domain.id}"
  host = "${element(ibm_compute_vm_instance.hyperledger_vm.*.hostname, count.index)}"
  ttl = 300
  type = "a"
  count = "${var.vm_count}"
}
