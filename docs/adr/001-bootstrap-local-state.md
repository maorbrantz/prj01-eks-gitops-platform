# ADR 001: bootstrap stack uses local state

Status: accepted

## Context

Every other Terraform stack in this repo stores its state in an S3 bucket with a
DynamoDB lock table. That backend does not exist until something creates it, and
the thing that creates it is the bootstrap stack (`terraform/bootstrap/`). If the
bootstrap stack tried to store its own state in the bucket it provisions, the
first `terraform init` would fail because the backend is not there yet, and a
`terraform destroy` would delete the bucket that holds the very state describing
the destroy. That is the classic chicken-and-egg problem for remote state.

## Decision

The bootstrap stack keeps its state on the local filesystem (the default Terraform
backend). No `backend "s3"` block is configured for `terraform/bootstrap/`. Every
downstream stack does configure the S3 backend, pointing at the bucket and lock
table this stack creates.

The local state file is never committed. The repo `.gitignore` already ignores
`*.tfstate` and `*.tfstate.*`, so `terraform.tfstate` for the bootstrap stack
stays out of git.

## Consequences

The bootstrap state lives only on whoever ran it last. That is acceptable because
the bootstrap resources (state bucket, lock table, OIDC provider, CI roles) change
rarely and are cheap to reconcile: `terraform plan` against an already-applied
stack shows no changes, and if the local state is ever lost the resources can be
re-imported or recreated. Since the account is a sandbox and these resources are
few, I accept the loss of remote state and locking for this one stack in exchange
for breaking the dependency cycle. If this grew into a shared, long-lived setup I
would move bootstrap state into a separately managed backend (a second, manually
created bucket) rather than share the bucket it provisions.
