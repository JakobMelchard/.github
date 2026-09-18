terraform {
  required_version = ">= 1.8"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.6"
    }
  }
  # State is local by default and gitignored. Point a backend here when there is
  # a second machine that needs to apply.
}

# Token from GITHUB_TOKEN. Repo-level resources need `repo`; org settings need `admin:org`.
provider "github" {
  owner = var.org
}
