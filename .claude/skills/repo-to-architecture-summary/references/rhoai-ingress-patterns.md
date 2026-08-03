# RHOAI Ingress and Migration Patterns

RHOAI 3.x controllers create different resources than 2.x. Read controller
code to identify current behavior. This reference covers the patterns to look
for and the complete ingress stack that must be documented.

## Primary ingress pattern (RHOAI 3.x)

- Creates `HTTPRoute` CRs (Gateway API) for main service traffic
- Uses `kube-rbac-proxy` sidecars for authentication
- Look for: `gateway.networking.k8s.io/v1beta1` or `v1`, `HTTPRoute`, `kube-rbac-proxy` container

## Legacy pattern (RHOAI 2.x, being phased out)

- Creates OpenShift `Route` CRs for main service traffic
- Uses `oauth-proxy` sidecars for authentication
- Look for: `routev1.Route`, `oauth-proxy` container

## Routes still appear in 3.x code

RHOAI 3.x controllers may ALSO create OpenShift Route CRs intentionally for:
- **Redirect routes**: Routes pointing at nginx/redirect services to redirect
  old URLs to new Gateway API URLs (e.g., `dashboard_redirects.go` creates
  Route CRs for legacy dashboard and gateway hostnames that 301-redirect to the
  new hostname)
- **OAuth callback routes**: Routes needed for OAuth flows that must use the
  legacy Route mechanism
- **OcpRoute ingress mode**: An alternative ingress mode using Routes instead of
  Gateway API

Do NOT skip or dismiss Route-creating code just because it's in a 3.x
controller. Document ALL resources the controller creates, regardless of
whether they use "old" or "new" patterns. The distinction is what traffic the
resource handles, not whether it's legacy.

## How to identify in controller code

Search for ALL of these patterns across ALL `.go` files in controller
directories:

```go
HTTPRoute                    // Creating Gateway API HTTPRoutes
gateway.networking.k8s.io    // Gateway API imports
Gateway                      // Gateway CR (the ingress entry point itself)
EnvoyFilter                  // Istio EnvoyFilter CRs (traffic shaping, header manipulation)
networking.istio.io          // Istio API imports (for EnvoyFilter, VirtualService)
envoy                        // Envoy proxy configuration or deployment
kube-rbac-proxy             // Auth sidecar (3.x primary)
routev1.Route               // OpenShift Routes (may be redirects, OAuth callbacks, or OcpRoute mode)
oauth-proxy                 // OAuth proxy (2.x pattern)
Route                       // Any Route creation (check purpose: redirect vs primary ingress)
nginx                       // Redirect services (301 redirects from legacy URLs)
```

## Examples

- `kubeflow/components/odh-notebook-controller/controllers/`: Creates HTTPRoutes + kube-rbac-proxy sidecars per notebook
- `rhods-operator/internal/controller/services/gateway/`: Deploys platform Gateway for HTTPRoutes to reference
- `rhods-operator/internal/controller/services/gateway/dashboard_redirects.go`: Creates nginx Deployment + Service + OpenShift Route CRs that redirect legacy dashboard/gateway URLs to the new Gateway API hostname
- Document ALL resources the controller creates — both HTTPRoutes AND Routes, noting the purpose of each

## Gateway API / Ingress controller documentation requirements

When an operator manages ingress infrastructure, document the FULL stack:
- Search for: `gateway.networking.k8s.io`, `Gateway`, `HTTPRoute`, `GRPCRoute`, `TLSRoute`
- Search for: `EnvoyFilter`, `networking.istio.io`, `envoy` (Envoy data plane)
- Search for: `kube-rbac-proxy`, `oauth-proxy` (auth sidecars)
- Check controller code to understand what ingress infrastructure is deployed

RHOAI 3.x deploys a full ingress stack — ALL of these must be documented:
1. **Gateway CR** (`gateway.networking.k8s.io`): Defines the platform ingress entry point (e.g., "data-science-gateway")
2. **Envoy proxy**: The data plane pod that serves Gateway API traffic
3. **EnvoyFilter CRs** (`networking.istio.io/v1alpha3`): Traffic shaping, header manipulation, CORS, auth enforcement
4. **HTTPRoute CRs**: Per-component routing rules referencing the parent Gateway
5. **kube-rbac-proxy sidecars**: Auth enforcement per component pod
6. **OpenShift Routes**: Redirect routes (legacy URL → new Gateway URL), OAuth callbacks
7. **nginx redirect Deployments**: 301 redirect services for legacy hostnames

This is **critical ingress architecture** — must be documented even if not in
static manifests. Read controller reconcile logic to understand what gets
deployed at runtime.

## Sidecar containers (injected by controllers)

Search controller code for sidecar injection patterns. Look for: `Container{}`
structs being added to Pod specs in reconcile loops.

RHOAI 3.x pattern: `kube-rbac-proxy` sidecars for authentication
- Typically on port 8443/TCP
- Fronts main application container
- Enforces RBAC before proxying to application

Document in Network Architecture → Services section.
Example: "kube-rbac-proxy sidecar (8443/TCP) → application container (8080/TCP)"
