variable "name_prefix" {
  description = "String to use as prefix on resource name"
  type = string
}
variable "name_suffix" {
  description = "String to use as suffix on resource name"
  type = string
  default = null
}
variable "bucket_name" {
  description = "S3 Bucket name for terraform state"
  type = string
  default = null
}
variable "tags" {
  description = "Common tags of resources"
  type = map(string)
  default = {}
}
variable "log_bucket_name" {
  description = "S3 Bucket name for bucket log"
  type = string
  default = null
}
variable "log_prefix" {
  description = "Prefix in bucket log"
  type = string
  default = null
}