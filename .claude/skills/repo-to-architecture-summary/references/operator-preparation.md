# Operator Preparation — Legacy Route Only

Synthesis and partial routes skip this step entirely.

## opendatahub-operator

```bash
make get-manifests
```

This clones kustomize manifests into `./opt/` directory. These manifests are
used at deployment time when components are enabled. Critical for analyzing
actual deployment configuration (not just operator code). Without this step,
you'll miss component deployment details.

## rhods-operator (RHOAI 3.x+)

This operator deploys the platform's entire ingress infrastructure. Use the
analyzer baseline first, then thoroughly inspect any ingress/dynamic-resource
surface it does not establish:

1. Enumerate controller directories only to identify dynamic surfaces not
   covered by the analyzer — run `find internal/controller -type d` and
   `find controllers -type d 2>/dev/null`
2. For controller directories whose dynamic behavior is not already covered
   by the analyzer, run `ls -la` to see all files, then read every `.go` file
   and every template file (`*.tmpl.yaml`, `*.yaml`, `*.tmpl`) in that
   directory and its `resources/` subdirectory. Do not reread files whose
   relevant behavior is analyzer-covered.
3. Pay special attention to these directories when their relevant behavior is
   not covered by the analyzer (non-exhaustive — do not skip an uncovered
   dynamic surface):
   - `internal/controller/services/gateway/` — Gateway API, Envoy, EnvoyFilter, kube-rbac-proxy
   - `internal/controller/services/gateway/resources/` — YAML/template files for Gateway, EnvoyFilter, Deployments
   - Any directory matching `*dashboard*`, `*route*`, `*redirect*`, `*ingress*`, `*auth*`

The ingress stack this operator deploys includes ALL of:
- **Gateway API** (`gateway.networking.k8s.io`): Gateway CR defining the platform ingress entry point
- **Envoy proxy**: The data plane that serves Gateway API traffic (deployed as a pod)
- **EnvoyFilter CRs** (`networking.istio.io/v1alpha3`): Traffic shaping, header manipulation, auth integration
- **kube-rbac-proxy**: Authentication/authorization sidecar injected into component pods
- **OpenShift Routes**: Redirect routes for legacy URLs, OAuth callback routes
- **nginx redirect services**: Deployment + Service + Route for 301 redirects from old hostnames
- **HTTPRoute CRs**: Per-component routing rules referencing the parent Gateway

Missing ANY of these produces an incomplete ingress architecture. Document
every resource the controllers create.

## Other repositories

Skip to discovery (Step 3).
