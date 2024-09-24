terraform {
  required_providers {
    github = {
      source = "integrations/github"
      version = "6.3.0"
    }
  }
}
provider "github" {
    token = "my_token"
}

resource "github_repository" "terraformrepo" {
  name = "terraformrepo"
  description = "This repository is created using the the Terraform code"
  visibility = "public"
}