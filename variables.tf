variable "tags" {
  description = "Tags to apply on resource"
  type        = map(string)
  default = {
    owner = "terraform"
  }
}

variable "location" {
}

variable "docker_image" {
}

variable "appservice_sku" {
}