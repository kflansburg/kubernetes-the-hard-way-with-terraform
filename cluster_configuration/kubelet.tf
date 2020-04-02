data "template_file" "kubelet-config" {
  count = length(var.cluster_ips.workers.public)

  template = "${file("${path.root}/templates/kubelet-config.yaml")}"
  vars = {
    POD_CIDR = "10.200.${count.index}.0/24"
    HOSTNAME = "worker-${count.index}"
  }
}

data "template_file" "kubelet-service" {
  template = "${file("${path.root}/templates/kubelet.service")}"
  vars = {
  }
}

resource "null_resource" "kubelet-config" {
  count = length(var.cluster_ips.workers.public)

  triggers = {
    config  = data.template_file.kubelet-config[count.index].rendered
    service = data.template_file.kubelet-service.rendered
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = var.cluster_ips.workers.public[count.index]
    private_key = var.ssh_key
  }

  provisioner "file" {
    content     = data.template_file.kubelet-config[count.index].rendered
    destination = "/home/ubuntu/kubelet-config.yaml"
  }

  provisioner "file" {
    content     = data.template_file.kubelet-service.rendered
    destination = "/home/ubuntu/kubelet.service"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cp /home/ubuntu/kubelet.service /etc/systemd/system/kubelet.service",
      "sudo cp /home/ubuntu/kubelet-config.yaml /var/lib/kubelet/kubelet-config.yaml",
    ]
  }
}
