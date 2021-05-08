resource "google_service_account" "spark-jobs-sa" {
  account_id   = "spark-jobs-sa"
  display_name = "Service account for Airflow"
}

resource "google_service_account_key" "spark-jobs-sa-key" {
  service_account_id = google_service_account.spark-jobs-sa.name
}

resource "kubernetes_secret" "google-application-credentials" {
  metadata {
    name = "spark-jobs-sa-credentials"
    namespace = "default"
  }
  data = {
    "credentials.json" = base64decode(google_service_account_key.spark-jobs-sa-key.private_key)
  }
}

resource "google_storage_bucket" "jars-bucket" {
  name = "tbd-2021l-123-jars-storage"
  location = var.location
  force_destroy = true
}

resource "google_storage_bucket_iam_binding" "binding" {
  depends_on = [google_service_account.spark-jobs-sa]
  bucket = google_storage_bucket.jars-bucket.name
  role = "roles/storage.admin"
  members = [
    "serviceAccount:${google_service_account.spark-jobs-sa.email}",
  ]
}

resource "helm_release" "spark-operator" {
  name = "spark-operator"
  repository = "https://googlecloudplatform.github.io/spark-on-k8s-operator"
  chart = "spark-operator"
  version = "1.1.0"
  namespace = "default"
  create_namespace = true

  set {
    name = "serviceAccounts.spark.create"
    value = "true"
  }

  set {
    name = "serviceAccounts.spark.name"
    value = "spark"
  }
}