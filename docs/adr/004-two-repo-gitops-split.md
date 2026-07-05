# ADR 004: two-repo GitOps split

Status: accepted

## Context

There are two things that change on different clocks: the application code (the
FastAPI api, the SQS worker, the nginx web tier) and the desired state of the
cluster (which image tag is deployed, which addons are installed, how the network
is shaped). They can live in one repo or two.

A single repo is simpler to clone and reason about. But it couples the two
lifecycles: an infra change shows up in the app's history, an app change shows up
in the platform's history, and CODEOWNERS and branch protection have to
distinguish paths within one repo rather than whole repos.

## Decision

Two repos. `prj01-eks-gitops-platform` (this one) holds Terraform and the GitOps
desired state that ArgoCD watches. `prj01-linkpulse-app` holds the application
code and the Helm chart.

They meet in exactly one place: the LinkPulse ArgoCD Application is a multi-source
app. One source is the Helm chart in the app repo. The other source is this repo,
referenced as `$values`, providing the environment values file
(`gitops/apps/dev/linkpulse/values.yaml`) where the image tag lives. So the chart
ships from the app repo, and what to deploy and how to configure it for this
environment ships from here.

## Consequences

The app repo never edits infrastructure, and the platform repo never forces an app
rebuild. Promoting a new image is a one-line change to the values file in this
repo, opened as a pull request by the app repo's release workflow, so promotion is
reviewable and auditable and does not touch the chart. Prod promotion is the same
move: copy the proven tag from the dev values to the prod values.

The cost is a bit more ceremony. A change that spans both (say, a new environment
variable that the chart and the values must both learn about) is two pull requests
across two repos instead of one. For this project that separation is the point, and
the cross-repo tag-bump automation keeps the common case (ship a new image) down to
a single merge.
