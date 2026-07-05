# ADR 003: EKS with ArgoCD over simpler options

Status: accepted

## Context

The goal of this project is a platform that looks and behaves like a real
production Kubernetes setup, not the smallest thing that could serve a URL
shortener. A managed container service like ECS or App Runner, or a plain
EC2/Docker host, would run LinkPulse for less money and less moving parts. But
none of them exercise the platform skills this project exists to show: cluster
addons, progressive delivery, policy enforcement, node autoscaling on spot, and
GitOps reconciliation. The point is the platform, and the platform is Kubernetes.

Given Kubernetes, something has to reconcile desired state onto the cluster. The
two realistic GitOps engines are ArgoCD and Flux.

## Decision

I run the application on EKS, and I drive the cluster with ArgoCD in an
app-of-apps layout.

EKS over self-managed Kubernetes because the managed control plane, the EKS
add-ons, and Pod Identity remove a large amount of undifferentiated work and let
the project focus on the platform layer. EKS over ECS because ECS does not give
you the addon ecosystem (Karpenter, Kyverno, cert-manager, external-secrets) that
this project is built to demonstrate.

ArgoCD over Flux mostly for the UI and the app-of-apps model. ArgoCD's application
tree is easy to read and easy to capture as proof, its multi-source Applications
let the app chart and the environment values live in different repos cleanly, and
its self-managed install (ArgoCD reconciling its own chart from git) is a tidy
demonstration of the pattern. Flux would do the job too; this is a preference, not
a correctness call.

## Consequences

The cluster costs more than a simpler runtime and takes longer to stand up, which
is exactly why the ephemeral `make up` / `make down` pattern exists (see the cost
analysis). In exchange the platform demonstrates the full GitOps loop: every change
to the cluster goes through git, ArgoCD reconciles it, and drift is corrected
automatically. If this were a real product with a small team and no need for the
addon ecosystem, ECS or App Runner would be the honest choice, and I would not
reach for EKS just to have it.
