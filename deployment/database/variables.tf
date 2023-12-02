variable "user_name" {
  type    = string
  default = "profile-service-rfg"
}

variable "user_pass" {
  type      = string
  sensitive = true
  default   = "profile-service-pass"
}

