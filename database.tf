## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl


module "oci-adb" {
  source                                  = "github.com/oracle-quickstart/oci-adb"
  adb_password                            = var.autonomous_database_admin_password
  compartment_ocid                        = var.compartment_ocid
  adb_database_cpu_core_count             = var.autonomous_database_cpu_core_count
  adb_database_data_storage_size_in_tbs   = var.autonomous_database_data_storage_size_in_tbs
  adb_database_db_name                    = var.autonomous_database_db_name
  adb_database_db_version                 = var.ATP_database_db_version
  adb_database_display_name               = var.autonomous_database_db_version
  adb_database_freeform_tags              = var.autonomous_database_freeform_tags
  adb_database_license_model              = var.autonomous_database_license_model
  adb_database_db_workload                = "DW"
  use_existing_vcn                        = var.autonomous_database_private_endpoint
  adb_private_endpoint                    = var.autonomous_database_private_endpoint
  vcn_id                                  = var.autonomous_database_private_endpoint ? oci_core_virtual_network.vcn.id : null
  adb_nsg_id                              = var.autonomous_database_private_endpoint ? oci_core_network_security_group.ATPSecurityGroup.id : null
  adb_private_endpoint_label              = var.autonomous_database_private_endpoint ? var.autonomous_database_private_endpoint : null
  adb_subnet_id                           = var.autonomous_database_private_endpoint ? oci_core_subnet.subnet_3.id : null
  is_data_guard_enabled                   = var.autonomous_database_is_data_guard_enabled
  defined_tags                            = { "${oci_identity_tag_namespace.ArchitectureCenterTagNamespace.name}.${oci_identity_tag.ArchitectureCenterTag.name}" = var.release }
}
