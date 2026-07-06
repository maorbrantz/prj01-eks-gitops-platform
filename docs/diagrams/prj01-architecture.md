# prj01 EKS GitOps Platform, architecture diagram

Companion guide for [prj01-architecture.drawio](prj01-architecture.drawio). The exported [PNG](prj01-architecture.drawio.png) has the diagram XML embedded, so it opens directly in draw.io for editing.

## Request flow

1. A user resolves `linkpulse.prj1.maorbrantz.com` through Route 53 (the subdomain is delegated from GoDaddy once; ExternalDNS manages the records).
2. The browser talks HTTPS to the internet-facing ALB, TLS terminated with the ACM certificate. HTTP redirects to HTTPS.
3. The ALB forwards to the linkpulse web pods (nginx), which serve the frontend and proxy `/api` and bare short codes to the api service.
4. The api stores link mappings in DynamoDB and emits a click event to SQS on every redirect.
5. The worker long-polls SQS, aggregates clicks per short code per day into DynamoDB, and failed messages redrive to the DLQ after five attempts.

## Delivery flow

1. A merge to the app repo triggers GitHub Actions: tests, scans, then an image push to ECR authenticated with OIDC (no stored AWS keys).
2. A bot PR bumps the image tag in this repo. Merging it is the deployment.
3. ArgoCD pulls the desired state from GitHub and syncs the cluster. Nobody runs kubectl.
4. The api ships as an Argo Rollouts canary: 20 then 50 then 100 percent, each step gated by Prometheus analysis (success rate and p95 latency). A failing canary aborts and rolls back on its own.

## Services in the diagram

| Element | Purpose |
|---|---|
| Route 53 | Public zone for `prj1.maorbrantz.com`, records managed by ExternalDNS |
| ACM | Certificate for the ALB HTTPS listener |
| ALB | Internet-facing ingress, created by the AWS Load Balancer Controller |
| EKS `prj01-dev` | Kubernetes 1.33, system node group in private subnets |
| ArgoCD | GitOps engine, app-of-apps, self-managed |
| Prometheus, Grafana, Loki | Metrics, dashboards as code, logs; feeds canary analysis |
| Kyverno | Enforced policies: no latest tags, non-root, resource limits, no privileged |
| Karpenter | Provisions spot worker nodes on demand, consolidates them away after load |
| ECR | The three linkpulse images, pushed by CI over OIDC |
| SQS + DLQ | Click event queue with redrive policy |
| DynamoDB | `prj01-links` and `prj01-click-stats` tables |

## Design notes

- Nodes live in private subnets; only the ALB is public.
- Every AWS access from a pod uses EKS Pod Identity. There are no static credentials in the cluster or in CI.
- The full rationale lives in the ADRs under [docs/adr](../adr/).
