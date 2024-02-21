variable "cidr_id"{
    default = "192.168.0.0/16"
}
variable "project"{
    default = "demo-project"
}

variable "env"{
    default = "dev"
}

variable "private_subnet_cidr"{
    default = "192.168.0.0/20"
}

variable "public_subnet_cidr"{
    default = "192.168.16.0/20"
}