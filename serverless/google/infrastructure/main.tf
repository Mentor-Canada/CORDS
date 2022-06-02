provider "google" {
  project     = "matteproject"
  region      = "us-central1"
  credentials = file("credentials.json")
}

# This gets the default service account for us to use it later.
data "google_compute_default_service_account" "default_serv_acc" {
}

resource "google_project_iam_member" "firestore_owner_binding" {
  project = "matteproject"
  role    = "roles/datastore.owner"
  member  = "serviceAccount:${data.google_compute_default_service_account.default_serv_acc.email}"
}

resource "google_cloud_run_service" "gc_run_service" {
    name     = "mattecordscloudrunservice"
    location = "us-central1"

    metadata {
      annotations = {
        "run.googleapis.com/client-name" = "terraform"
      }
    }

    template {
      spec {
        containers {
          image = "gcr.io/matteproject/cords-image"
          resources {
            limits = {
              cpu = "1.0"
              memory = "2Gi"
            }
          }
        }
      }
    }
 }

 data "google_iam_policy" "noauth" {
   binding {
     role = "roles/run.invoker"
     members = ["allUsers"]
   }
   
   depends_on  = [
     google_cloud_run_service.gc_run_service
   ]
 }

 resource "google_cloud_run_service_iam_policy" "noauth" {
   location    = google_cloud_run_service.gc_run_service.location
   project     = google_cloud_run_service.gc_run_service.project
   service     = google_cloud_run_service.gc_run_service.name

   policy_data = data.google_iam_policy.noauth.policy_data

   depends_on  = [
     google_cloud_run_service.gc_run_service
   ]
}