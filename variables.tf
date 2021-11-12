variable "access_key" {
    description = "access key for provider"
    type = string
}

variable "secret_key" {
    description = "secret key for provider"
    type = string
}


variable "region" {
    description = "AWS region for main VPC"
    type = string
    default = "us-east-2"
}

variable "vpc_cidr" {
    description = "Main VPC cidr block"
    type        = string
    default     = "10.10.0.0/16"
}

variable "subnet_newbit" {
    description = "Extra bits for the subnets netmask"
    type    = number 
    default = 8
}

variable "az_count" {
    description = "Amount of availability zones to use"
    type        = number
    default     = 2
}

variable "webservers_type" {
    description = "instance type"
    type        = string
    default     = "t3.micro"
}

variable "webservers_app" {
    description = "Application to be deploy on webserver[index]"
    type        = list(string)
    default     = ["apache", "nginx"]
    
    validation {
        condition       = alltrue([
                            for app in var.webservers_app : can(regex("apache|nginx", app))
                        ])
        error_message   = "Webserver Apps must be nginx or apache."
    }
}