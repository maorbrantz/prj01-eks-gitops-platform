# ADR 006: Pod Identity over static credentials

Status: accepted

## Context

Several pods need AWS permissions. The api reads and writes DynamoDB and sends to
SQS. The worker consumes SQS and writes DynamoDB. Platform controllers need their
own access: external-dns manages Route53 records, external-secrets reads Secrets
Manager, the load balancer controller manages ALBs. There are three ways to give a
pod AWS credentials: bake an access key into the pod, give the node an instance
role broad enough for every pod on it, or bind an IAM role to the specific service
account the pod runs as. The first two are how credentials leak and how a
compromised pod gets more than it should.

The service-account approach itself comes in two forms on EKS: IRSA (an OIDC
federation with a role annotation on the service account) and EKS Pod Identity (an
association resource plus the pod-identity-agent addon). Pod Identity is the newer
mechanism and does not require wiring the cluster's OIDC provider into every role's
trust policy.

## Decision

Every pod that touches AWS uses EKS Pod Identity. No static keys anywhere. No app
pod relies on node-level AWS permissions.

Each association binds an IAM role to a specific (namespace, service account) pair,
and the role's policy is scoped to exactly what that pod needs. The api role can
touch only the two DynamoDB tables and the click queue. The worker role can consume
the click queue and write the stats table. external-dns can manage records only in
the one hosted zone it owns. The chart names the service accounts to match the
associations, so the wiring is declarative on both sides.

Pod Identity over IRSA because the association is a cleaner model: the trust lives
in the association resource, not scattered across every role's trust policy, and it
does not need the cluster OIDC provider threaded through each role. The
`eks-pod-identity-agent` addon is enabled on the cluster and does the credential
injection.

## Consequences

A compromised pod can reach only its own narrowly scoped resources, and there are
no long-lived secrets to rotate or leak. This pairs with the CI side, where GitHub
Actions assumes scoped roles through OIDC rather than storing AWS keys as repo
secrets, so the whole system has zero static AWS credentials end to end.

One honest caveat sits on the CI side, not here: the `prj01-ci-apply` role carries
AdministratorAccess because the platform provisions VPC, EKS, and IAM across the
account, and this is a throwaway sandbox. Production would attach a permission
boundary to that role. That is noted in the runbook and does not change the pod
identity model, which stays least-privilege.
