variable "ssh-allowlist" {
  type        = list(string)
  description = "IP(s) allowed for SSH access to the dev box"
}
variable "location" {
  type        = string
  description = "Location from verified location list (az account list-locations -o table)"
}
variable "resource-prefix" {
  type        = string
  description = "Prefix to apply to all resources"
}
variable "storage-prefix" {
  type        = string
  description = "Prefix (shorthand) to apply to shared storage account"
}
variable "cdbvm-username" {
  type        = string
  description = "VM username"
}
variable "cdbvm-size" {
  type        = string
  description = "VM size (az vm list-sizes --location $location -o table)"
}
variable "cdbvm-nic-accelerated-networking" {
  type        = string
  description = "Enable accelerated networking for NIC. Ensure it is supported by VM size."
}
variable "cdbvm-comp-name" {
  type        = string
  description = "VM computer name"
}
variable "tag-stage" {
  type        = string
  description = "Stage tag assigned to all resources"
}
