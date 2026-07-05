# ADR 002: single NAT gateway in dev

Status: accepted

## Context

Private nodes need outbound internet access to pull images, reach the EKS API,
and talk to AWS service endpoints. That egress goes through a NAT gateway. The
standard high-availability pattern is one NAT gateway per availability zone, so
that losing a single AZ does not cut egress for the nodes in the other zones.
Each NAT gateway costs roughly $0.045/hr plus data processing, so three of them
add up quickly for a cluster that only exists during a demo session.

## Decision

The dev VPC uses a single NAT gateway shared by all three AZs
(`single_nat_gateway = true`). Private subnets in every AZ route their egress
through that one gateway.

## Consequences

This cuts the NAT bill to a third of the per-AZ setup, which is the right call
for an ephemeral cluster that gets torn down after each work session. The
downside is a real single point of failure: if the AZ holding the NAT gateway
has an outage, private nodes in all three AZs lose outbound internet until it
recovers. For a portfolio dev environment that is acceptable, because the whole
cluster is disposable and rebuildable with one command.

For a production environment I would switch to one NAT gateway per AZ
(`single_nat_gateway = false`, `one_nat_gateway_per_az = true`) so an AZ failure
only affects that zone. That decision belongs in the prod env config, which is a
later phase.
