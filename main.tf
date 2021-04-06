
#the subnet used by the VPC
resource "google_compute_subnetwork" "playground-subnet" {
  project       = var.project
  name          = "playground-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.playground-vpc.id
}

#create a VPC for the compute instances
resource "google_compute_network" "playground-vpc" {
  project                 = var.project
  name                    = "playground-vpc"
  auto_create_subnetworks = false
}

#cloud router for NAT
resource "google_compute_router" "router" {
  project = var.project
  name    = "playground-router"
  region  = google_compute_subnetwork.playground-subnet.region
  network = google_compute_network.playground-vpc.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  project                            = var.project
  name                               = "playground-router-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

#this creates the service accounts for each compute instance
resource "google_service_account" "default" {
  for_each     = var.compute_sa
  project      = var.project
  account_id   = each.value.account_id
  display_name = "${each.key} Service Account"
  depends_on   = [
    google_project_service.project,
  ]
}

#the firewall rule below exposes ports ot the world
resource "google_compute_firewall" "default" {
  name    = "pg-vpc-firewall"
  project = var.project
  network = google_compute_network.playground-vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "8980", "3000"]
  }
}

#the ports below are exposed internally on the project vpc
resource "google_compute_firewall" "internal" {
  name    = "pg-vpc-internal"
  project = var.project
  network = google_compute_network.playground-vpc.name
  source_ranges = [var.subnet_cidr]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["9042", "9092", "9200", "9999", "8080", "80", "443", "25"]
  }
  allow {
    protocol = "udp"
    ports    = ["161", "9999"]
  }
}

#Enable the required APIs on the project
resource "google_project_service" "project" {
  for_each = toset(var.apis)
  project = var.project
  service = each.value

  disable_dependent_services = true
}

#Additional disks for each compute instance
resource "google_compute_disk" "default" {
  for_each = var.disks
  project = var.project
  name  = each.value.name
  type  = "pd-standard"
  zone  = var.zone
  size  = each.value.size
  }

# Create the compute instances
resource "google_compute_instance" "default" {
  for_each     = var.vms
  project      = var.project
  name         = each.value.name
  machine_type = each.value.machine_type
  hostname     = each.value.hostname
  zone         = var.zone
  tags         = toset(each.value.tags)

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
      size = "50"
    }
  }
  attached_disk {
    source = google_compute_disk.default[each.key].name
  }

  network_interface {
    network    = google_compute_network.playground-vpc.id
    subnetwork = google_compute_subnetwork.playground-subnet.id
    network_ip = each.value.ipaddr

    dynamic "access_config" {
    for_each = each.value.name == "gateway" || each.value.name == "opennms" || each.value.name == "grafana" ? ["1"] : []
    content {
      nat_ip = null
      }
    }
  }

  metadata = {
    i_need = "some_metadata"
    ssh-keys = "${var.ssh_user}:${file(var.pub_key_file)}"
#    deploy-key = file(var.deploy_key_priv)
    vpw = var.vpw
    minion_location = each.value.name
  }

  metadata_startup_script = file("bootstraps/${each.value.name}.bootstrap.sh")

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = "${each.value.sa}@${var.project}.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }
}

# Assign each compute instance service account to the osLogin role so the can
# read their own metadata. we really only need compute.instances.get, this 
# just gives us the least perms.
resource "google_project_iam_member" "iam_things" {
  for_each = google_compute_instance.default
  project  = var.project
  role     = "roles/compute.osLogin"
  member   = "serviceAccount:${each.value.service_account[0].email}"
  depends_on   = [
    google_project_service.project
  ]
}

# display the public IPs for each instance when we're done
output "ip" {
  value = {
     for i in google_compute_instance.default:
              i.name => i.network_interface.0.access_config.0.nat_ip if length(i.network_interface.0.access_config) != 0
  }
  description = "nat_ip"
 }
