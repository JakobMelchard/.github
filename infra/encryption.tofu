# State and plan encryption (OpenTofu >= 1.8 for variables in this block).
# The state is committed to git at state/terraform.tfstate so CI can apply, so
# it must never be written in plaintext: `enforced` refuses the unencrypted
# method. Same passphrase as infra/terraform/tailscale (Infisical core/dev
# TOFU_STATE_PASSPHRASE, CI secret of the same name).
#
# A .tofu file, not .tf: OpenTofu reads it, Terraform ignores it.
#
# Do not rename the key provider or the method: their names are stored in the
# encrypted file's metadata. Rotate the passphrase with a `fallback` block.

variable "state_passphrase" {
  description = "Passphrase for state and plan encryption (>= 16 chars). Local: Infisical TOFU_STATE_PASSPHRASE via the Makefile. CI: secret TOFU_STATE_PASSPHRASE."
  type        = string
  sensitive   = true
}

terraform {
  encryption {
    key_provider "pbkdf2" "state" {
      passphrase = var.state_passphrase
    }

    method "aes_gcm" "state" {
      keys = key_provider.pbkdf2.state
    }

    state {
      method   = method.aes_gcm.state
      enforced = true
    }

    plan {
      method   = method.aes_gcm.state
      enforced = true
    }
  }
}
