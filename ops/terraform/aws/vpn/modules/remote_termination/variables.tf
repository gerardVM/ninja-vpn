variable "suffix" {
    type        = string
    description = "A suffix to append to resource names."
}

variable "function_name" {
    type        = string
    description = "The name of the lambda function."
}

variable "eip_id" {
    type        = string
    description = "The ID of the EIP to release."
}

variable "sender_email" {
    type        = string
    description = "The email address that the notification is sent from."
}

variable "ses_region" {
    type        = string
    description = "The AWS region that the notification is sent from."
}

variable "region" {
    type        = string
    description = "The AWS region that the user deployed his resources in."
}

variable "receiver_email" {
    type        = string
    description = "The email address that the notification is sent to."
}

variable "tags" {
    type        = map(string)
    description = "A map of tags to add to all resources."
}
