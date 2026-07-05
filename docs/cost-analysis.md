# Cost analysis

This platform is built to run in bursts, not to sit up. The design assumption is
that a session looks like `make up`, do the work or the demo, `make down`. The
numbers below are for `il-central-1`, which runs a little higher than the larger
regions, and they are approximate.

## While running

| Item | Roughly per hour |
|---|---|
| EKS control plane | $0.10 |
| System node group, 2x t3.medium | ~$0.10 |
| NAT gateway (single) | ~$0.05 |
| ALB | ~$0.03 |
| Karpenter spot bursts under load | ~$0.01 to $0.04 |
| DynamoDB, SQS, ECR, CloudWatch logs | pennies |

Call it about $0.30 to $0.35 per hour with a light load, a bit more while a load
test has Karpenter nodes up. A full working or demo session of a couple of hours is
a few dollars.

## If it were left running

Left up around the clock, the fixed pieces dominate. The control plane, the two
system nodes, the NAT gateway, and the ALB run whether or not anyone is using the
app, so they set the floor. At roughly $0.28 per hour for those four alone, a month
of never tearing it down is on the order of $200, before any load-driven spot
nodes. That is the number the ephemeral pattern exists to avoid.

## The ephemeral strategy

Tear it down after every session. Because the entire platform is in Terraform and
git, rebuilding is `make up FORCE=1` then `make argocd`, and ArgoCD reconciles the
whole addon tree and the app back to Synced and Healthy on its own. What survives a
teardown costs almost nothing (see the runbook): the state bucket, the ECR images,
the Route53 zone, and the OIDC and CI roles. So the steady-state cost of the
project when nobody is working on it is close to zero, and the cost of a session is
bounded by how long the session runs.

## Spot versus on-demand for the workloads pool

Application pods run on Karpenter nodes, spot first with on-demand fallback (ADR
005). Spot runs roughly a third of the on-demand price for the same instance, so a
`t3a.medium` that costs on the order of $0.04 per hour on-demand is around $0.012 to
$0.015 on spot. Under a load test the workloads pool might bring up one node for a
few minutes, which is why the spot burst line above is a cent or a few cents rather
than a fixed cost. On-demand is the fallback, so the worst case when spot is
unavailable is that those same bursts cost the on-demand rate for a while, still
only while the load is present, because consolidation removes the node about a
minute after it goes idle.

## The single NAT trade-off

The dev VPC uses one NAT gateway for all three AZs instead of one per AZ (ADR 002).
That is roughly $0.05 per hour instead of roughly $0.15, so it saves about $0.10 an
hour, which matters for a cluster measured in hours. The cost is a single point of
failure: if the AZ holding the NAT has an outage, private nodes in all three zones
lose egress until it recovers. For a disposable dev cluster that is an easy trade.

## What prod-grade would change

If this had to be a real always-on production platform, the cost shape would change
and so would the architecture:

- One NAT gateway per AZ, removing the egress single point of failure and roughly
  tripling the NAT line.
- Separate dev and prod clusters instead of one cluster, which doubles the control
  plane and system node floor but isolates blast radius.
- High-availability control-plane-adjacent components: multiple ArgoCD replicas,
  and a Prometheus setup sized and retained for real (remote write or a longer
  local retention with more disk) rather than the demo footprint here.
- A permission boundary on the CI apply role instead of AdministratorAccess, and a
  private EKS API endpoint with restricted CIDRs.

None of those are free, and none of them are worth paying for on a portfolio
cluster that lives for the length of a demo. They are the honest list of what I
would change the day this stopped being ephemeral.
