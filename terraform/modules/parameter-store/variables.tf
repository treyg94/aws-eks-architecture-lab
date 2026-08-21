variable "name" {
  description = "Fully qualified name of the SSM parameter."
  type        = string

  validation {
    condition     = startswith(var.name, "/")
    error_message = "The SSM parameter name must be a fully qualified path beginning with a slash."
  }
}

variable "description" {
  description = "Description of the application configuration parameter."
  type        = string
}

variable "value" {
  description = "Non-sensitive String value stored in Parameter Store."
  type        = string
}

variable "tags" {
  description = "Tags applied to the SSM parameter."
  type        = map(string)
  default     = {}
}
