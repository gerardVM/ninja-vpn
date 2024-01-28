locals {
    config      = yamldecode(file("${path.root}/../../../../config.yaml"))
}