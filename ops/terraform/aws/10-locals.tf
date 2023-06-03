locals {
    config      = yamldecode(file("${path.root}/../../../config.yaml"))
    countdown   = try(local.config.countdown, null)
}