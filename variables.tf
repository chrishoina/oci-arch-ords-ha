## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

# Variables
variable "tenancy_ocid" {}
variable "compartment_ocid" {
  default = ""
}
#variable "user_ocid" {
#  default = ""
#}
#variable "fingerprint" {
#  default = ""
#}
#variable "private_key" {
#  default = ""
#}
#variable "private_key_path" {
#  default = ""
#}
#variable "private_key_password" {
#  default = ""
#}
variable "region" {}
variable "autonomous_database_admin_password" {}
variable "availability_domain" {
  default = ""
}
variable "availability_domain_name" {
  default = ""
}

variable "release" {
  description = "Reference Architecture Release (OCI Architecture Center)"
  default     = "1.1"
}

#variable "ssh_public_key" {
#  default = ""
#}
variable "ssh_public_key_path" {
  default = ""
}

#variable "ssh_provided_key" {
#  default = ""
#}

variable "lb_shape" {
  default = "flexible"
}

variable "flex_lb_min_shape" {
  default = "10"
}

variable "flex_lb_max_shape" {
  default = "100"
}

# OS Images
variable "instance_os" {
  description = "Operating system for compute instances"
  default     = "Oracle Linux"
}

variable "linux_os_version" {
  description = "Operating system version for all Linux instances"
  default     = "9.5"
}

variable "number_of_midtiers" {
  default = 1
}

variable "instance_shape" {
  default = "VM.Standard.E4.Flex"
}

variable "instance_flex_shape_ocpus" {
  default = 1
}

variable "instance_flex_shape_memory" {
  default = 16
}

variable "autonomous_database_private_endpoint" {
  default = true
}

variable "autonomous_database_cpu_core_count" {
  default = 1
}

variable "autonomous_database_data_storage_size_in_tbs" {
  default = 1
}

variable "autonomous_database_db_name" {
  default = "ORDSADB"
}

variable "autonomous_database_db_version" {
  default = "23ai"
}

variable "autonomous_database_defined_tags_value" {
  default = "value"
}

variable "autonomous_database_display_name" {
  default = "ORDSADB"
}

variable "autonomous_database_freeform_tags" {
  default = {
    "Owner" = "ADB"
  }
}

variable "autonomous_database_license_model" {
  default = "LICENSE_INCLUDED"
}

variable "oci_database_autonomous_database_wallet" {
  default = "Wallet_ORDSADB.zip"
}

variable "autonomous_database_private_endpoint_label" {
  default = "autonomous_database_private_endpoint"
}

variable "autonomous_database_is_data_guard_enabled" {
  default = false
}

locals {
# Dictionary Locals
# I've updated these to the latest shapes. These are the ones available with Linux 8 and 9. 
  compute_flexible_shapes = [
    "VM.Standard.A2.Flex",
    "VM.Optimized3.Flex",
    "VM.Standard.E4.Flex",
    "VM.Standard.E3.Flex",
    "VM.Standard3.Flex",
    "VM.DenseIO.E4.Flex",
    "VM.Standard.E5.Flex"
  ]
  # Checks if is using Flexible Compute Shapes
  is_flexible_node_shape = contains(local.compute_flexible_shapes, var.instance_shape)

  availability_domain_name = var.availability_domain_name == "" ? lookup(data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain], "name") : var.availability_domain_name
  #private_key              = var.private_key == "" ? file(var.private_key_path) : var.private_key
  #ssh_public_key           = var.ssh_public_key == "" ? file(var.ssh_public_key_path) : var.ssh_public_key
}
