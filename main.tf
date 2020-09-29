resource "oci_core_vcn" "my_vcn" {
     #Required
     cidr_block = "10.0.0.0/16"
     compartment_id = var.compartment_id

     #Optional
     display_name = "MyVCN"
     dns_label    = "myvcn"
 }

 resource "oci_core_internet_gateway" "internet_gateway" {
     #Required
     compartment_id = var.compartment_id
     vcn_id = oci_core_vcn.my_vcn.id

     #Optional
     display_name = "internetGateway"
 }

 resource "oci_core_nat_gateway" "nat_gateway" {
      #Required
      compartment_id = var.compartment_id
      vcn_id = oci_core_vcn.my_vcn.id

      #Optional
      display_name = "natGateway"
  }

  resource "oci_core_route_table" "public_route_table" {
      #Required
      compartment_id = var.compartment_id
      vcn_id = oci_core_vcn.my_vcn.id

      #Optional
      display_name = "Public Route Table"
      route_rules {
          #Required
          network_entity_id = oci_core_internet_gateway.internet_gateway.id

          #Optional
          destination = "0.0.0.0/0"
          destination_type = "CIDR_BLOCK"
      }
  }

  resource "oci_core_route_table" "private_route_table" {
     #Required
     compartment_id = var.compartment_id
     vcn_id = oci_core_vcn.my_vcn.id

     #Optional
     display_name = "Private Route Table"
     route_rules {
         #Required
         network_entity_id = oci_core_nat_gateway.nat_gateway.id

         #Optional
         destination = "0.0.0.0/0"
         destination_type = "CIDR_BLOCK"
     }
 }

 resource "oci_core_security_list" "public_security_list" {
    #Required
    compartment_id = var.compartment_id
    vcn_id = oci_core_vcn.my_vcn.id

    #Optional
    display_name = "PublicSubnet"
    egress_security_rules {
        #Required
        destination = "0.0.0.0/0"
        protocol = "all"
    }
    ingress_security_rules {
        description = "icmp"
        protocol    = "1"
        source      = "10.23.0.0/16"
    }
    ingress_security_rules {
      description = "icmp"
      protocol    = "1"
      source      = "10.23.0.0/16"
      icmp_options {
        type = 3
      }
    }
    ingress_security_rules {
      description = "icmp"
      protocol    = "1"
      source      = "0.0.0.0/0"
      icmp_options {
        type = 3
        code = 4
      }
    }
    ingress_security_rules {
      protocol    = "6"
      source      = "0.0.0.0/0"
      tcp_options {
        min = 80
        max = 80
      }
    }
}

resource "oci_core_security_list" "private_security_list" {
   #Required
   compartment_id = var.compartment_id
   vcn_id = oci_core_vcn.my_vcn.id

   #Optional
   display_name = "PrivateSubnet"
   egress_security_rules {
       #Required
       destination = "0.0.0.0/0"
       protocol = "all"
   }
   ingress_security_rules {
       description = "icmp"
       protocol    = "1"
       source      = "10.23.0.0/16"
   }
   ingress_security_rules {
     description = "icmp"
     protocol    = "1"
     source      = "10.23.0.0/16"
     icmp_options {
       type = 3
     }
   }
   ingress_security_rules {
     description = "icmp"
     protocol    = "1"
     source      = "0.0.0.0/0"
     icmp_options {
       type = 3
       code = 4
     }
   }
   ingress_security_rules {
     protocol    = "6"
     source      = "10.0.0.0/24"
     tcp_options {
       min = 3389
       max = 3389
     }
   }
}


resource "oci_core_subnet" "public_subnet" {
    #Required
    cidr_block = "10.0.0.0/24"
    compartment_id = var.compartment_id
    vcn_id = oci_core_vcn.my_vcn.id

    #Optional
    display_name = "PublicSubnet"
    dns_label = "publicsubnet"
    prohibit_public_ip_on_vnic = false
    route_table_id = oci_core_route_table.public_route_table.id
    security_list_ids = [oci_core_security_list.public_security_list.id]
}

resource "oci_core_subnet" "private_subnet" {
    #Required
    cidr_block = "10.0.1.0/24"
    compartment_id = var.compartment_id
    vcn_id = oci_core_vcn.my_vcn.id

    #Optional
    display_name = "PrivateSubnet"
    dns_label = "privatesubnet"
    prohibit_public_ip_on_vnic = true
    route_table_id = oci_core_route_table.private_route_table.id
    security_list_ids = [oci_core_security_list.private_security_list.id]
}


resource "oci_core_instance" "webserver_instance" {
    #Required
    availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[1]["name"]
    compartment_id = var.compartment_id
    shape = "VM.Standard2.1"

    create_vnic_details {

        #Optional
        assign_public_ip = true
        private_ip = "10.0.0.2"
        subnet_id = oci_core_subnet.public_subnet.id
    }
    display_name = "WebServer"
    fault_domain = "FAULT-DOMAIN-1"
    metadata = {
        user_data = base64encode(file("./bootstrap"))
    }
    source_details {
        #Required
        source_id = "ocid1.image.oc1.iad.aaaaaaaa27ux7kzbvoyl6mefq42cxyrqjexhb4nu2ynj44z5mbjnju5jrzpq"
        source_type = "image"
    }
    preserve_boot_volume = false
}
