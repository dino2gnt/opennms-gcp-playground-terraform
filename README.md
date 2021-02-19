OpenNMS GCP playground
==================

This is a terraform script to provision an OpenNMS playground in GCP, including: 
* The OpenNMS application
* An OpenNMS Minion, configured to collect flows 
* Elasticsearch for persisting Flow documents
* Grafana, for visualizing Flow data and performance metrics
* Apache Kafka for OpenNMS <-> Minion communication
* All hosts generating sflow noise using hsflow
* All hosts exposing SNMP (internally on the VPC) for collection

I do not expect this will be useful to anyone else, and it isn't written with your usability in mind.

However, if you chose to use this, you should:

* create a fresh GCP project
* create a dedicated service account for terraform with owner privs
* generate a key for this service account
* Download the key and use it as the creds for terraform.
* fork [the Ansible configuration repo](https://github.com/dino2gnt/opennms-gcp-playground-ansible.git) and update all the bootstraps to point to your fork. 
* Use the ansible-vault command to encrypt a password for Grafana, then update the role/grafana/vars/main.yml.  This is your vault password for var `vpw`.
* Fix the opennms users.xml to use a known password hash so you can log in.
* deal with any other inconsistencies and cockups you come across

Required variables: 
* `project` is probably important.
* `pub_key_file` - path to an ssh public key file (for shell access)
* `vpw` - an ansible vault password.

Optional variables:
* If you use a private github repo for the Ansible config, you can uncomment the various bits to pass in a path to your deployment private key as `deploy_key_priv` .
* anything else can be overridden on the command line or in a `tfvars` as you see fit.

The included compute instance [startup scripts](https://github.com/dino2gnt/opennms-gcp-playground-terraform/tree/main/bootstraps) files point to [another repo](https://github.com/dino2gnt/opennms-gcp-playground-ansible.git) the contains sufficient Ansible to install and configure most of the nuts and bolts of the environment. If you're going to use this, you should probably fork that repo and update your startup scripts to pull from it instead of mine. 
You will need to manually enable the OpenNMS Helm plugin in Grafana and configuring the various datasources, but flow data should be available almost immediately.

The tinyvpn instance was intended to be used as an OpenVPN gateway, however, this work is still to be done.
