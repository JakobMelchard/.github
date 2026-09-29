.PHONY: help fmt validate plan apply

help:
	@echo "infra — GitHub as code for the JakobMelchard org"
	@echo ""
	@echo "Run from infra. CI (infra.yml) plans on PRs and applies on main; these"
	@echo "targets are the fallback for a local apply."
	@echo "  fmt        Format OpenTofu files"
	@echo "  validate   Validate configuration (no credentials needed)"
	@echo "  plan       Show execution plan"
	@echo "  apply      Apply the saved plan, stage state/terraform.tfstate"
	@echo ""

TF = tofu
# Secrets from the Infisical project linked in .infisical.json (core, env dev).
INFISICAL_ENV ?= dev
SECRETS = infisical run --silent --env=$(INFISICAL_ENV) --
# State and plan encryption passphrase (encryption.tofu) from Infisical, the
# GitHub token from gh. Both expand inside the child shell, never on argv.
TOFU = $(SECRETS) sh -c 'GITHUB_TOKEN="$$(gh auth token)" TF_VAR_state_passphrase="$$TOFU_STATE_PASSPHRASE" exec $(TF) "$$@"' tofu
STATE = state/terraform.tfstate

fmt:
	$(TF) fmt -recursive

# Own data dir: in a dir initialized with the backend, init -backend=false
# would try to read the encrypted state without the passphrase.
validate: fmt
	TF_DATA_DIR=.terraform/validate $(TF) init -backend=false -input=false >/dev/null
	TF_DATA_DIR=.terraform/validate $(TF) validate

plan: validate
	$(TOFU) init -input=false >/dev/null
	$(TOFU) plan -out=plan.tfplan

# Every apply rewrites the ciphertext, even without changes; only a new
# serial is a real state change. Stages the state, never commits or pushes.
apply:
	@old=$$(jq -r .serial $(STATE) 2>/dev/null || echo none); \
	$(TOFU) apply plan.tfplan && \
	new=$$(jq -r .serial $(STATE)) && \
	if [ "$$old" = "$$new" ]; then \
	  git checkout -- $(STATE) 2>/dev/null || true; \
	  echo "state unchanged (serial $$new)"; \
	else \
	  git add $(STATE); \
	  echo "state serial $$old -> $$new, staged $(STATE). Commit and push it now:"; \
	  echo "  git commit -m 'chore(infra): update encrypted state' && git push"; \
	fi
