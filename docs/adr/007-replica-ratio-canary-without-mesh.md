# ADR 007: replica-ratio canary without a service mesh

Status: accepted

## Context

The api ships through an Argo Rollouts canary. Argo Rollouts can split traffic two
ways. With a traffic-routing provider (an ALB, an Ingress, or a service mesh like
Istio or Linkerd) it can send an exact percentage of requests to the canary
regardless of how many pods each version has. Without one, it uses the replica
ratio: the share of traffic a version gets is the share of pods it has, because the
Service load-balances across all ready pods evenly.

Traffic routing is more precise, but it costs a real dependency. An ALB-based split
needs the rollout to own the ingress and manage target groups per version, and a
mesh adds a whole data plane to install, secure, and reason about.

## Decision

The api uses a replica-ratio canary with no traffic-routing provider. The steps are
setWeight 20, pause, setWeight 50, pause, then full promotion. Traffic reaches the
api through the web nginx tier and the api Service, so a weight is honestly
expressed as a share of the api pods, and the Service does the actual splitting.

## Consequences

At the HPA floor of two api replicas, 20 percent rounds to one canary pod against
two stable, and 50 percent is one against one, so the weights are approximate at
low replica counts. That is fine here. The canary's job is to expose the new
version to a fraction of real traffic long enough for analysis to judge it, not to
hit an exact percentage. The rounding is visible in the captured run
(`docs/proof/rollout-canary-steps.txt`) and it does not change the outcome.

I get progressive delivery, automated analysis, and automatic rollback without
installing or operating a mesh, which keeps the platform's moving parts down to
what it actually needs. If the api later needed exact percentage splits, header or
cookie-based routing, or mirroring, that is the point at which adding an ALB traffic
router or a mesh would earn its keep. Today it would be weight without benefit.
