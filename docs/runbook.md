# Runbook

Operating notes for the prj01-dev platform. This covers standing the cluster up
from nothing, the day-to-day deploy and rollback moves, a few incidents I have
actually hit, and tearing it all down.

Everything assumes the `prj01` AWS profile and `il-central-1`. The SSO session
behind that profile expires after a few hours, so if Terraform suddenly fails with
a token or credentials error, that is almost always the cause. Refresh it with:

    aws sso login --sso-session ness-sandbox-5

## Fresh bootstrap

Run these in order. Most sessions only need the last of them, because the first two
change rarely.

1. DNS delegation, one time only, already done. The public hosted zone
   `prj1.maorbrantz.com` (`Z059069021REM6GKSJ2A3`) was created once by hand and
   delegated from GoDaddy with NS records on the parent `maorbrantz.com`. Terraform
   references this zone with a data source and never creates or destroys it.
   Recreating the zone changes its NS set and breaks the GoDaddy delegation, so
   leave it alone.

2. The bootstrap stack, rarely. This provisions the Terraform state bucket
   (`prj01-tf-state-149536464688`), the DynamoDB lock table (`prj01-tf-lock`), the
   GitHub OIDC provider, and the three CI roles. It uses local state (ADR 001),
   because it is the thing that creates the remote backend everything else uses.

       make bootstrap                 # fmt, init, validate, plan
       cd terraform/bootstrap && AWS_PROFILE=prj01 terraform apply

3. The dev environment. This is the cluster and everything AWS-side around it: VPC,
   EKS, the system node group, Karpenter's IAM and node role, the data resources
   (DynamoDB, SQS, ECR), the addon IAM roles, and the DNS/cert wiring.

       make plan                      # review first
       make up FORCE=1                # terraform apply, provisions real resources

   `make up` refuses to run without `FORCE=1` on purpose, so an apply is always a
   deliberate act.

4. ArgoCD and the app-of-apps. Once the cluster is reachable, install ArgoCD and
   hand control to git.

       make argocd                    # runs scripts/bootstrap-cluster.sh

   The script is idempotent. It helm-installs ArgoCD from the pinned chart
   (`10.1.2`), applies the platform AppProject, and applies the root Application.
   After this, watch the tree converge:

       kubectl -n argocd get applications.argoproj.io -o wide

   Give it a few minutes. The addons pull their charts, cert-manager issues the
   ACM-backed certificate, external-dns writes the records, and the LinkPulse app
   comes up in `linkpulse-dev`. When every Application reads Synced and Healthy the
   platform is up and the app is serving at `https://linkpulse.prj1.maorbrantz.com`.

## Day two

Deploying a new application version. You do not deploy by hand. Merge to the app
repo's main, its release workflow builds and pushes the image and opens a pull
request here that bumps the tag in `gitops/apps/dev/linkpulse/values.yaml`. Merge
that, ArgoCD syncs, and Argo Rollouts runs the canary. The full walk is in
`docs/gitops-flow.md`.

Promoting to prod. Copy the proven tag from the dev values to the prod values in a
pull request. Same artifact, no rebuild.

Watching a rollout in flight:

    kubectl -n linkpulse-dev get rollout linkpulse-api -w
    kubectl argo rollouts get rollout linkpulse-api -n linkpulse-dev

Pausing a rollout (to hold at the current step):

    kubectl argo rollouts pause linkpulse-api -n linkpulse-dev
    kubectl argo rollouts promote linkpulse-api -n linkpulse-dev   # resume

Rolling back. The honest rollback is git: revert the tag-bump pull request so the
values file points back at the previous image, and let ArgoCD reconcile. For an
immediate abort of an in-flight rollout before the git revert lands:

    kubectl argo rollouts abort linkpulse-api -n linkpulse-dev

Abort scales the canary down and leaves the stable ReplicaSet serving.

Forcing a sync if you do not want to wait for the poll:

    kubectl -n argocd patch application linkpulse-dev --type merge \
      -p '{"operation":{"sync":{}}}'

## Incidents

Canary aborted. A rollout that aborts leaves stable serving, so the app is up, but
something judged the new version bad. Check, in order: the rollout status and
message (`kubectl argo rollouts get rollout linkpulse-api -n linkpulse-dev`), the
canary pod logs for the new image, and once the analysis layer is live, the
AnalysisRun that failed (`kubectl -n linkpulse-dev get analysisrun`) and the
Prometheus queries behind it (5xx ratio and p95 against the thresholds). If the new
image is genuinely bad, revert the tag-bump pull request and let it roll back
through git.

Pods stuck Pending, Karpenter checklist. Work down this list:

- Is there a Karpenter node coming? `kubectl get nodeclaims -o wide`. If a
  NodeClaim exists but is not Ready, the node is still booting; give it 30 to 60
  seconds.
- No NodeClaim at all? Check the controller logs
  (`kubectl -n kube-system logs deploy/karpenter`) for why it will not provision.
- Nodes come up on-demand only and never spot? This is the one that cost me time.
  The account was missing the `AWSServiceRoleForEC2Spot` service-linked role, and
  every spot fleet request failed with
  `AuthFailure.ServiceLinkedRoleCreationNotPermitted` while Karpenter fell back to
  on-demand. Create it once at the account level:

      aws iam create-service-linked-role --aws-service-name spot.amazonaws.com

- Pods request more than the NodePool cap? The workloads NodePool is capped at 32
  vCPU. A pod asking for more than any allowed instance size will never schedule.

SSO token expiry during a local Terraform run. Symptoms are a sudden
credentials/expired-token error partway through a plan or apply, or an operation
that was working a minute ago now failing to reach AWS. The sandbox SSO token lasts
only a few hours. Re-run `aws sso login --sso-session ness-sandbox-5` and retry.
This has bitten a load-test capture mid-run before, so if a long operation dies
near the end, check the token before assuming anything is actually broken.

## Teardown and rebuild

Tear the cluster down at the end of a session:

    make down FORCE=1                 # terraform destroy of the dev env

Like `make up`, `make down` needs `FORCE=1` so it is never accidental. This
destroys the dev environment: the cluster, the VPC, the NAT gateway, the ALB, and
the Karpenter nodes. Because it is all in git, rebuilding is `make up FORCE=1`
followed by `make argocd`.

What survives a `make down`, because it belongs to the bootstrap stack or is
referenced by data source, not owned by the dev env:

- The Terraform state bucket (`prj01-tf-state-149536464688`) and lock table.
- The ECR repositories and the images in them, so a rebuild does not have to
  re-push.
- The Route53 hosted zone `prj1.maorbrantz.com` and its GoDaddy delegation.
- The GitHub OIDC provider and the CI roles.

What it costs while down: effectively nothing. S3 and DynamoDB hold a few small
objects, ECR holds a handful of images (a lifecycle policy keeps only the last ten
per repo), and the hosted zone is a small fixed monthly charge. The expensive parts
(the control plane, the nodes, the NAT gateway, the ALB) are all gone. See
`docs/cost-analysis.md` for the numbers.
