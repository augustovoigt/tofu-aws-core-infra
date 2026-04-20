############################################################
# AWS Lambda Layer - Cryptography - Variables             🇧🇷
############################################################

variable "bucket_name" {
  description = "Bucket name for the layer"
  type        = string
  default     = ""
}

variable "create" {
  description = "Whether to create this Lambda layer (and upload its artifact)."
  type        = bool
  default     = true
}
