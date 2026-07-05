# ADR 005: Karpenter spot-first with on-demand fallback

Status: accepted

## Context

Application pods that do not fit on the two system nodes need somewhere to run, and
that somewhere should be cheap and should disappear when the load does. Karpenter
provisions nodes directly for pending pods and consolidates them away when they go
idle, which fits the ephemeral pattern better than a fixed autoscaling group. The
open question is capacity type. Spot is roughly a third of the on-demand price but
can be reclaimed, and `il-central-1` has thinner spot capacity than the larger
regions.

## Decision

The workloads NodePool prefers spot and falls back to on-demand. It allows a wide
set of instance types (c, m, r, and t families, medium through 2xlarge) so that
when one instance type has no spot capacity, Karpenter can try another before
giving up on spot. If no spot capacity is available at all, it launches on-demand
rather than leaving pods pending. Consolidation runs one minute after a node goes
idle, and the NodePool is capped at 32 vCPU.

## Consequences

Most of the time application pods run on cheap spot nodes, and when spot is
unavailable the app still runs, just at on-demand price for a while. Consolidation
keeps the node count honest: when load drops, the extra node is removed and the
cluster returns to the two system nodes.

One finding is worth recording because it cost real debugging time. Spot did not
work at first. Every spot fleet request failed with
`AuthFailure.ServiceLinkedRoleCreationNotPermitted`, and Karpenter fell back to
on-demand exactly as designed, so the platform kept working but nothing ever landed
on spot. The cause was not thin capacity, it was a missing account-level
service-linked role, `AWSServiceRoleForEC2Spot`. Creating it once fixed spot for
good:

    aws iam create-service-linked-role --aws-service-name spot.amazonaws.com

After that, consolidation replaced the on-demand node with a `t3a.medium` spot node
of the same type. The full capture is in `docs/proof/karpenter-scale-out.txt`, and
the runbook lists this role as the first thing to check when Karpenter nodes will
not come up on spot. Spot interruptions are handled by Karpenter's interruption
queue; workloads that cannot tolerate a reclaim should carry a PodDisruptionBudget
and topology spread, which is a follow-up rather than a shipped guarantee today.
