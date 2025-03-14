## Copyright © 2021, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

# ADB Wallet

resource "local_file" "autonomous_data_warehouse_wallet_file" {
  content_base64 = module.oci-adb.adb_database.adb_wallet_content
  filename       = var.ATP_tde_wallet_zip_file
}


resource "null_resource" "compute-script1" {
  depends_on = [oci_core_instance.compute_instance, module.oci-adb.adb_database, oci_core_network_security_group_security_rule.ATPSecurityEgressGroupRule, oci_core_network_security_group_security_rule.ATPSecurityIngressGroupRules]

  count = var.number_of_midtiers

  # Install ORDS, SQLcl and set up the firewall rules
  provisioner "remote-exec" {

    connection {
      type        = "ssh"
      user        = "opc"
      host        = oci_core_instance.compute_instance[count.index].public_ip
      private_key = tls_private_key.key.private_key_pem
      agent       = false
      timeout     = "2m"
    }
    inline = [

      ## Original command: "sudo yum install ords -y",
      ## Original command: "sudo yum install sqlcl -y",
      "sudo dnf install ords -y",
      "sudo dnf install sqlcl -y",
      "sudo dnf install graalvm21-ee-17",
      "sudo dnf install graalvm21-ee-17-javascript",
      "echo 'export JAVA_HOME=/usr/lib64/graalvm/graalvm21-ee-17' >> ~/.bashrc",
      "echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc",
      "source ~/.bashrc",
      "sudo firewall-cmd --permanent --zone=public --add-port=8080/tcp",
      "sudo firewall-cmd --reload",
    ]
  }

  # Stage ORDS conf files
  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = oci_core_instance.compute_instance[count.index].public_ip
      private_key = tls_private_key.key.private_key_pem
      agent       = false
      timeout     = "2m"
    }
    source      = "${path.module}/ords/ords_conf.zip"
    destination = "/home/opc/ords_conf.zip"
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "opc"
      host        = oci_core_instance.compute_instance[count.index].public_ip
      private_key = tls_private_key.key.private_key_pem
      agent       = false
      timeout     = "2m"
    }
    source      = var.ADB_wallet_zip_file

# This variable for the zip file is referencing the tde_wallet_ordsatp.zip file. So that is where it is
# taking it from. See the variables.tf file for more details.

    destination = "/home/opc/${var.ADB_wallet_zip_file}"
  }


  #Configure and start ORDS
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "opc"

# This references the count property in the resource section of the compute.tf file. And the "count"
# is taken from the 'number_of_midtiers' variable. Again, that variable originates from the variable.tf
# file.

      host        = oci_core_instance.compute_instance[count.index].public_ip
      private_key = tls_private_key.key.private_key_pem
      agent       = false
      timeout     = "2m"
    }

# https://linux.die.net/man/1/chown

    inline = [
      "sudo mv /home/opc/Wallet*.zip /home/oracle/wallet.zip",
      "sudo chown oracle:oinstall /home/oracle/wallet.zip",
      "sudo mv /home/opc/ords_conf.zip /opt/oracle/ords/",
      "sudo chown oracle:oinstall /opt/oracle/ords/ords_conf.zip",
      "sudo su - oracle -c 'unzip -q /opt/oracle/ords/ords_conf.zip -d /opt/oracle/ords/'",
      "sudo su - oracle -c 'sed -i 's/PASSWORD_HERE/${var.autonomous_database_admin_password}/g' /opt/oracle/ords/conf/ords/create_user.sql'",
      "sudo su - oracle -c 'sed -i 's/_NODE_NUMBER/${count.index}/g' /opt/oracle/ords/conf/ords/create_user.sql'",
      "sudo su - oracle -c 'sed -i 's/PASSWORD_HERE/${var.autonomous_database_admin_password}/g' /opt/oracle/ords/conf/ords/conf/databases/default/pool.xml'",
      "sudo su - oracle -c 'sed -i 's/DATABASE_NAME_HERE/${var.autonomous_database_db_name}/g' /opt/oracle/ords/conf/ords/conf/databases/default/pool.xml'",
      "sudo su - oracle -c 'sed -i 's/_NODE_NUMBER/${count.index}/g' /opt/oracle/ords/conf/ords/conf/databases/default/pool.xml'",
    # "sudo su - oracle -c 'java -jar /opt/oracle/ords/ords.war configdir /opt/oracle/ords/conf'",
      "sudo su - oracle -c 'sql -cloudconfig /home/oracle/wallet.zip admin/${var.autonomous_database_admin_password}@${var.autonomous_database_db_name}_low @/opt/oracle/ords/conf/ords/create_user.sql'",
      "sudo su - oracle -c 'ords --config /opt/oracle/ords/conf serve'",
    ]

  }

}
