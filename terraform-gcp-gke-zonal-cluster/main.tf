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

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.30.0, < 3"
    }
  }
}

# placed this here because it conflicts with terragrunt autogenerated files
provider "kubernetes" {
  host                   = google_container_cluster.default.endpoint
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = google_container_cluster.default.endpoint
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.default.master_auth[0].cluster_ca_certificate)
  }
}

data "google_client_config" "default" {}

resource "google_compute_network" "default" {
  #checkov:skip=CKV2_GCP_18:default firewall is okay for this use case
  name = "${local.gke_cluster_name}-network"

  auto_create_subnetworks = "false"
  project                 = var.project_id

  # everything in this solution is deployed regionally
  routing_mode = "REGIONAL"
}

# this will construct a vpc-native, private gke cluster. for effective routing from the regional external http load balancer,
# https://cloud.google.com/kubernetes-engine/docs/how-to/standalone-neg
resource "google_compute_subnetwork" "default" {
  #checkov:skip=CKV_GCP_26:vpc flow logs are not necessary in this context
  #checkov:skip=CKV_GCP_76:todo: check if this is a bug
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
  #checkov:skip=CKV2_GCP_18:control plane should be public
  #checkov:skip=CKV2_GCP_65:we want to have separated RBAC from google groups

  provider = google-beta
  project  = var.project_id
  name     = local.gke_cluster_name
  location = var.zone

  initial_node_count = var.num_nodes

  # enable cilium. if you want to use calico, enter
  # LEGACY_DATAPATH instead
  datapath_provider = "ADVANCED_DATAPATH"

  # enable workooad identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # security
  enable_shielded_nodes = true

  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  networking_mode = "VPC_NATIVE"
  network         = google_compute_network.default.name
  subnetwork      = google_compute_subnetwork.default.name

  node_config {
    # info on spot vms with gke:
    # https://cloud.google.com/kubernetes-engine/docs/how-to/spot-vms#create_a_cluster_with_enabled
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

    shielded_instance_config {
      enable_secure_boot = true
    }
  }

  logging_config {
    enable_components = [
      "SYSTEM_COMPONENTS"
    ]
  }

  release_channel {
    channel = var.release_channel
  }

  addons_config {
    # enable GCS backed volumes
    gcs_fuse_csi_driver_config {
      enabled = true
    }

    http_load_balancing {
      # this needs to be enabled for the neg to be automatically
      # created for the ingress gateway svc
      disabled = false
    }
  }

  private_cluster_config {
    # need to use private nodes for vpc-native gke clusters
    enable_private_nodes = true
    # allow private cluster master to be accessible outside of the network
    enable_private_endpoint = false
    master_ipv4_cidr_block  = local.master_ipv4_cidr_block
  }

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = local.cluster_ipv4_cidr_block
    services_ipv4_cidr_block = local.services_ipv4_cidr_block
  }

  default_snat_status {
    # more info on why snat needs to be disabled:
    # https://cloud.google.com/kubernetes-engine/docs/how-to/alias-ips#enable_pupis
    # this applies to vpc-native gke clusters
    disabled = true
  }

  master_authorized_networks_config {
    cidr_blocks {
      # because this is a private cluster, need to open access to the
      # master nodes in order to connect with kubectl
      cidr_block   = "0.0.0.0/0"
      display_name = "World"
    }
    gcp_public_cidrs_access_enabled = true
  }

  # allow cluster deletion
  deletion_protection = false
}

resource "time_sleep" "wait_for_kube" {
  depends_on = [google_container_cluster.default]
  # GKE master endpoint may not be immediately accessible, resulting in error, waiting does the trick
  create_duration = "30s"
}

resource "null_resource" "local_k8s_context" {
  depends_on = [time_sleep.wait_for_kube]
  provisioner "local-exec" {
    # update your local gcloud and kubectl credentials for the newly created cluster
    command = "for i in 1 2 3 4 5; do gcloud container clusters get-credentials ${local.gke_cluster_name} --project=${var.project_id} --zone=${var.zone} && break || sleep 60; done"
  }
}
