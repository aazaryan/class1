variable "tenancy_ocid" {
  default = "ocid1.tenancy.oc1..."
}
variable "compartment_id" {
  default = "ocid1.compartment.oc1..."
}

# get availability domain
data "oci_identity_availability_domains" "ADs" {
  compartment_id = var.tenancy_ocid
}
