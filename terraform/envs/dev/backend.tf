terraform {
  backend "s3" {
    bucket       = "prj01-tf-state-149536464688"
    key          = "envs/dev/terraform.tfstate"
    region       = "il-central-1"
    profile      = "prj01"
    encrypt      = true
    use_lockfile = true
  }
}
