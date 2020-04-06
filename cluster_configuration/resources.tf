provider "kubernetes" {
  load_config_file = "false"

  host = "https://${var.KUBERNETES_PUBLIC_ADDRESS}:6443"

  cluster_ca_certificate = tls_self_signed_cert.ca.cert_pem
  client_key             = tls_private_key.admin.private_key_pem
  client_certificate     = tls_locally_signed_cert.admin.cert_pem
}

resource "kubernetes_cluster_role" "kube-apiserver-to-kubelet" {
  depends_on = [
    null_resource.wait-kube-apiserver
  ]

  metadata {
    annotations = {
      "rbac.authorization.kubernetes.io/autoupdate" : "true"
    }
    labels = {
      "kubernetes.io/bootstrapping" : "rbac-defaults"
    }
    name = "system:kube-apiserver-to-kubelet"
  }

  rule {
    api_groups = [""]
    resources = [
      "nodes/proxy",
      "nodes/stats",
      "nodes/log",
      "nodes/spec",
      "nodes/metrics"
    ]
    verbs = ["*"]
  }
}

resource "kubernetes_cluster_role_binding" "system-kube-apiserver" {
  depends_on = [kubernetes_cluster_role.kube-apiserver-to-kubelet]

  metadata {
    name = "system:kube-apiserver"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:kube-apiserver-to-kubelet"
  }

  subject {
    kind      = "User"
    name      = "kubernetes"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "null_resource" "coredns" {
  depends_on = [
    null_resource.start-worker-services,
    null_resource.wait-kube-apiserver
  ]

  provisioner "local-exec" {
    working_dir = path.root
    command     = "kubectl --kubeconfig admin.kubeconfig apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns.yaml"
  }
}
