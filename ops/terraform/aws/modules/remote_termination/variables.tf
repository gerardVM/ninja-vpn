variable "function_name" {
    type        = string
    description = "The name of the lambda function."
}

variable "instance_id" {
    type        = string
    description = "The ID of the instance to terminate."
}

variable "eip_id" {
    type        = string
    description = "The ID of the EIP to release."
}

variable "email" {
    type        = string
    description = "The email address to send the notification to."
}

variable "tags" {
    type        = map(string)
    description = "A map of tags to add to all resources."
}
