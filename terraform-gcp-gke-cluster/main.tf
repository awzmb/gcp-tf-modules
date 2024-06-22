terraform {
  required_version = ">=1.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.25.0, < 6"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 5.25.0, < 6"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10.0, < 3"
    }

    null = {
      source  = "hashicorp/null"
      version = "> 3.0"
    }

    time = {
      source  = "hashicorp/time"
      version = "> 0.10"
    }
  }
}

data "google_project" "project" {}

data "google_client_config" "default" {}

resource "google_compute_network" "default" {
  name = var.network_name

  auto_create_subnetworks = "false"
  project                 = data.google_project.project.project_id

  # Everything in this solution is deployed regionally
  routing_mode = "REGIONAL"
}

# This will construct a VPC-native, private GKE cluster. For effective routing from the Regional External HTTP Load Balancer,
# having the VPC-native cluster is needed to make Gloo Edge's Envoy gateway-proxy pods routable via a standalone NEG.
# See links in the comments below for specifics. This page is a good place to understand the overall solution:
# https://cloud.google.com/kubernetes-engine/docs/how-to/standalone-neg

resource "google_compute_subnetwork" "default" {
  #checkov:skip=CKV_GCP_26:VPC flow logs are not necessary in this context
  ip_cidr_range = local.internal_subnet_cidr
  name          = "${local.gke_cluster_name}-subnet"
  project       = google_compute_network.default.project
  region        = var.region
  network       = google_compute_network.default.name

  private_ip_google_access   = true
  private_ipv6_google_access = true

  depends_on = [
    google_compute_network.default
  ]
}

resource "google_container_cluster" "default" {
  provider           = google-beta
  project            = var.project_id
  name               = local.gke_cluster_name
  location           = var.region
  initial_node_count = var.num_nodes
  # More info on the VPC native cluster: https://cloud.google.com/kubernetes-engine/docs/how-to/standalone-neg#create_a-native_cluster
  networking_mode = "VPC_NATIVE"
  network         = google_compute_network.default.name
  subnetwork      = google_compute_subnetwork.default.name
  # Disable the Google Cloud Logging service because you may overrun the Logging free tier allocation, and it may be expensive
  logging_service = "none"

  node_config {
    # More info on Spot VMs with GKE https://cloud.google.com/kubernetes-engine/docs/how-to/spot-vms#create_a_cluster_with_enabled
    spot         = true
    machine_type = var.machine_type
    disk_size_gb = var.disk_size
    tags         = ["${local.gke_cluster_name}"]
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/trace.append",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/servicecontrol",
    ]
  }

  addons_config {
    http_load_balancing {
      # This needs to be enabled for the NEG to be automatically created for the ingress gateway svc
      disabled = false
    }
  }

  private_cluster_config {
    # Need to use private nodes for VPC-native GKE clusters
    enable_private_nodes = true
    # Allow private cluster Master to be accessible outside of the network
    enable_private_endpoint = false
    master_ipv4_cidr_block  = local.master_ipv4_cidr_block
  }

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "5.0.0.0/16"
    services_ipv4_cidr_block = "5.1.0.0/16"
  }

  default_snat_status {
    # More info on why sNAT needs to be disabled: https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips#enable_pupis
    # This applies to VPC-native GKE clusters
    disabled = true
  }

  master_authorized_networks_config {
    cidr_blocks {
      # Because this is a private cluster, need to open access to the Master nodes in order to connect with kubectl
      cidr_block   = "0.0.0.0/0"
      display_name = "World"
    }
  }
}

resource "time_sleep" "wait_for_kube" {
  depends_on = [google_container_cluster.default]
  # GKE master endpoint may not be immediately accessible, resulting in error, waiting does the trick
  create_duration = "30s"
}

resource "null_resource" "local_k8s_context" {
  depends_on = [time_sleep.wait_for_kube]
  provisioner "local-exec" {
    # Update your local gcloud and kubectl credentials for the newly created cluster
    command = "for i in 1 2 3 4 5; do gcloud container clusters get-credentials ${local.gke_cluster_name} --project=${var.project_id} --zone=${var.zone} && break || sleep 60; done"
  }
}

