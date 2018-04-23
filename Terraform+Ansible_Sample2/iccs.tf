# Configure the IBM Cloud Provider
provider "ibm" {
  bluemix_api_key    = "${var.ibm_bmx_api_key}"
  softlayer_username = "${var.ibm_sl_username}"
  softlayer_api_key  = "${var.ibm_sl_api_key}"
}

# Create an SSH key. You can find the SSH key surfaces in the SoftLayer console under Devices > Manage > SSH Keys

data "ibm_compute_ssh_key" "key_1" {
  label = "key_1"
}

data "ibm_compute_image_template" "img_iccs" {
  name = "ibm-test"
}

data "ibm_dns_domain" "domain_vm" {
  name = "kylekr.com"
}

# Create a virtual server with the SSH key
resource "ibm_compute_vm_instance" "vm_iccs" {
  hostname          = "iccs01"
  domain            = "${data.ibm_dns_domain.domain_vm.name}"
  ssh_key_ids       = ["${data.ibm_compute_ssh_key.key_1.id}"]
  image_id          = "${data.ibm_compute_image_template.img_iccs.id}"
  datacenter        = "seo01"
  network_speed     = 100
  cores             = 1
  memory            = 1024
  tags = [
    "iccs"
  ]
  wait_time_minutes = 15
  count = "1"

  connection {
    user        = "root"
    type        = "ssh"
    private_key = "${file("~/.ssh/id_rsa")}"
    timeout     = "3m"
  }

  provisioner "remote-exec" {
    inline = [
      "hostname",
      "lsb_release -a"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get install -y python"
    ]
  }

  provisioner "local-exec" {
    command = <<EOF
      echo "[demo]" > inventory
      echo "${ibm_compute_vm_instance.vm_iccs.ipv4_address} ansible_ssh_user=root ansible_ssh_private_key_file=~/.ssh/id_rsa" >> inventory
      EOF
  }

  provisioner "local-exec" {
    command = <<EOF
      ANSIBLE_HOST_KEY_CHECKING=False \
      ansible-playbook -i inventory playbook.yaml
      EOF
  }
}

resource "ibm_dns_record" "dns_vm_iccs_01" {
  domain_id = "${data.ibm_dns_domain.domain_vm.id}"
  data = "${ibm_compute_vm_instance.vm_iccs.ipv4_address}"
  host = "${ibm_compute_vm_instance.vm_iccs.hostname}"
  ttl = 300
  type = "a"
  count = "${ibm_compute_vm_instance.vm_iccs.count}"
}
