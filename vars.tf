
variable "project" {
  type = string
  default = "opennms-playground"
}

variable "region" {
  type = string
  default = "us-central1"
}

variable "zone" {
  type = string
  default = "us-central1-c"
}

variable "subnet_cidr" {
  type = string
  default = "192.168.100.0/24"
}

variable "apis" {
  type    = list(string)
  default = ["iam.googleapis.com", "cloudresourcemanager.googleapis.com"]
}

variable "pub_key_file" {
  type = string
  default = ""
 }

# If you're using a private repo with a deploy key for Ansible, you can pass the private key path in here.
# This is added to instance metadata and referenced in the startup scripts. Uncomment the metadata 
# line in main.tf if you're going to use this.
variable "deploy_key_priv" {
  type = string
  default = ""
 }

variable "ssh_user" {
  type = string
  default = "dino2gnt"
 }

variable "vpw" {
  type = string
  default = ""
}

variable "disks" {
  description = "Map of extra disks to configure"
  type        = map
  default     = {
    kafka = {
        name = "kafka-disk",
        size = "100" 
    },
    opennms = {
        name = "opennms-disk",
        size = "10" 
    },
    elasticsearch = {
        name = "es-disk",
        size = "100" 
    },
    grafana = {
        name = "grafana-disk",
        size = "10"             #we don't use this for anything, but it keeps the loop nice.
    },
    tinyvpn = {
        name = "tinyvpn-disk",
        size = "10" 
    },
    minion = {
        name = "minion-disk",
        size = "10" 
    }
  }
}

variable "vms" {
  description = "Map out all the VMs to create"
  type        = map
  default     = {
    kafka = {
      name = "kafka1",
      machine_type = "n1-standard-1",
      hostname = "kafka1.playground.foo",
      tags = ["kafka","compute"],
      ipaddr = "192.168.100.10",
      sa = "kafka-compute-sa"
    },
    opennms = {
      name = "opennms",
      machine_type = "n1-standard-2",
      hostname = "opennms.playground.foo",
      tags = ["opennms","compute"],
      ipaddr = "192.168.100.20",
      sa = "opennms-compute-sa"
    },
    elasticsearch = {
      name = "elastic1",
      machine_type = "n1-standard-1",
      hostname = "elastic1.playground.foo",
      tags = ["elastic","compute"],
      ipaddr = "192.168.100.30",
      sa = "elastic-compute-sa"
    },
    grafana = {
      name = "grafana",
      machine_type = "n1-standard-1",
      hostname = "grafana.playground.foo",
      tags = ["grafana","compute"],
      ipaddr = "192.168.100.40",
      sa = "grafana-compute-sa"
    },
    minion = {
      name = "minion1",
      machine_type = "n1-standard-1",
      hostname = "minion1.playground.foo",
      tags = ["minion","compute"],
      ipaddr = "192.168.100.50",
      sa = "minion-compute-sa"
    },
    tinyvpn = {
      name = "gateway",
      machine_type = "f1-micro",
      hostname = "gateway.playground.foo",
      tags = ["vpn","compute"],
      ipaddr = "192.168.100.2",
      sa = "tinyvpn-compute-sa"
    }
  }
}

variable "compute_sa" {
  description = "service accounts for each compute vm"
  type        = map
  default     = {
    kafka = {
      account_id = "kafka-compute-sa"
    },
    opennms = {
      account_id = "opennms-compute-sa"
    },
    elastic = {
      account_id = "elastic-compute-sa"
    },
    grafana = {
      account_id = "grafana-compute-sa"
    },
    minion = {
      account_id = "minion-compute-sa"
    },
    tinyvpn = {
      account_id = "tinyvpn-compute-sa"
    }
  }
}
