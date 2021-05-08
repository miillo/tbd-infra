resource "kubernetes_secret" "git_secret" {
  metadata {
    name = "airflow-ssh-git-secret"
    namespace = "default"
  }

  data = {
    "id_rsa" = file(var.git_secret_path)
  }
}

resource "helm_release" "kube-airflow" {
  name = "airflow-stable"
  repository = "https://airflow-helm.github.io/charts"
  chart = "airflow"
  version = "8.0.9"
  namespace = "default"
  wait = false

  values = [
    file("${path.module}/resources/config.yaml")
  ]
  depends_on = [kubernetes_secret.git_secret]
}