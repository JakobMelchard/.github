terraform {
  required_version = ">= 1.8"
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.6"
    }
  }
  # State lives in git, encrypted (encryption.tofu). CI (infra.yml) commits it
  # back to main after apply. Only this path is tracked, see .gitignore.
  backend "local" {
    path = "state/terraform.tfstate"
  }
}

# Token from GITHUB_TOKEN. Local: a PAT with `repo` (org settings need
# `admin:org`). CI: an installation token of the org app (melchbot) with
# repository administration + variables write.
provider "github" {
  owner = var.org
}
