resource "tls_private_key" "kube-proxy" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "kube-proxy" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.kube-proxy.private_key_pem
  subject {
    common_name         = "system:kube-proxy"
    organization        = "system:node-proxier"
    organizational_unit = "Kubernetes The Hard Way"
    locality            = "Chicago"
    province            = "IL"
    country             = "US"
  }
}

resource "tls_locally_signed_cert" "kube-proxy" {
  cert_request_pem      = tls_cert_request.kube-proxy.cert_request_pem
  ca_key_algorithm      = "RSA"
  ca_private_key_pem    = tls_private_key.ca.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.ca.cert_pem
  allowed_uses          = ["cert_signing", "key_encipherment", "server_auth", "client_auth"]
  validity_period_hours = 8760
}

module "kube-proxy-config" {
  source = "../kubeconfig"

  name            = "kube-proxy"
  username        = "system:kube-proxy"
  CLUSTER_ADDRESS = var.KUBERNETES_PUBLIC_ADDRESS
  ca              = null_resource.ca-cert.triggers.content
  cert            = [tls_locally_signed_cert.kube-proxy.cert_pem]
  key             = [tls_private_key.kube-proxy.private_key_pem]
}

resource "null_resource" "kube-proxy-config-deployment" {
  count = length(var.cluster_ips.workers.public)

  triggers = {
    key = module.kube-proxy-config.kubeconfig[0]
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = var.cluster_ips.workers.public[count.index]
    private_key = var.ssh_key
  }

  provisioner "file" {
    content     = module.kube-proxy-config.kubeconfig[0]
    destination = "/home/ubuntu/kube-proxy.kubeconfig"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /var/lib/kube-proxy",
      "sudo cp /home/ubuntu/kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig"
    ]
  }
}