variable "instance_id" {
    type        = string
    description = "The ID of the instance to terminate."
}

variable "countdown" {
    type        = string
    description = "The time to wait before the instance is terminated."
}

variable "tags" {
    type        = map(string)
    description = "A map of tags to add to all resources."
}