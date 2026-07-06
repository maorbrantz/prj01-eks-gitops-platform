#!/usr/bin/env bash
# Bootstrap ArgoCD onto the prj01 cluster and hand control to the root app of apps.
#
# Idempotent: safe to run repeatedly. It helm upgrade/installs argocd from the
# same pinned chart and values that argocd later self manages, then applies the
# platform AppProject and the root Application. After this runs, every further
# change to gitops/ reaches the cluster through git, not kubectl.
set -euo pipefail

# pin here must match gitops/platform/argocd/application.yaml targetRevision
ARGOCD_CHART_VERSION="10.1.2"
ARGOCD_NAMESPACE="argocd"
ARGO_HELM_REPO="https://argoproj.github.io/argo-helm"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALUES_FILE="${REPO_ROOT}/gitops/platform/argocd/values.yaml"
BOOTSTRAP_DIR="${REPO_ROOT}/gitops/bootstrap"

# allow HELM_BIN override so a portable helm can be used without a system install
HELM_BIN="${HELM_BIN:-helm}"

echo "==> using helm: ${HELM_BIN}"
"${HELM_BIN}" version

echo "==> ensuring argo helm repo is present"
"${HELM_BIN}" repo add argo "${ARGO_HELM_REPO}" >/dev/null 2>&1 || true
"${HELM_BIN}" repo update argo >/dev/null

echo "==> installing/upgrading argocd chart ${ARGOCD_CHART_VERSION} into namespace ${ARGOCD_NAMESPACE}"
"${HELM_BIN}" upgrade --install argocd argo/argo-cd \
  --version "${ARGOCD_CHART_VERSION}" \
  --namespace "${ARGOCD_NAMESPACE}" \
  --create-namespace \
  --values "${VALUES_FILE}" \
  --wait \
  --timeout 10m

echo "==> applying AppProjects and the root Application (everything in gitops/bootstrap)"
kubectl apply -f "${BOOTSTRAP_DIR}"

echo "==> done. watch progress with:"
echo "    kubectl -n ${ARGOCD_NAMESPACE} get applications.argoproj.io -o wide"
