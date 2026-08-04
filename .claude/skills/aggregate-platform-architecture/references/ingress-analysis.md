# Platform Ingress Synthesis

Use this reference when producing the ingress portions of `PLATFORM.md`:
Platform Overview, Component Relationships, Platform Network Architecture,
Platform Security, Data Flows, Deployment Topology, and Platform Architectural
Analysis.

Ingress synthesis must connect the platform's request path across component
boundaries. A component summary can describe an endpoint or proxy in isolation,
but the platform view must determine whether that endpoint is used by a Gateway,
Route, Envoy filter, policy, or backend workload elsewhere in the platform.

## Inputs

Use the structured platform inventory first. Use component prose and bounded
source reads only to resolve relationships that the inventory does not express.

| Source | What it provides |
|--------|------------------|
| `arch-query platform-summary` | Aggregated gateways, routes, HTTP endpoints, Services, workloads, dependencies, controller watches, security evidence, and source-linked cross-cutting evidence |
| Component JSON files | Source-linked resource ownership, route/backend references, endpoint contracts, deployments, Services, auth records, and integration facts |
| Component map | Component names, repository ownership, aliases, distribution metadata, and checkout paths when available |
| Component architectural analysis | Semantic roles and request-flow explanations for key ingress, operator, proxy, and backend components |
| Bounded source reads | Exact resource construction or runtime configuration when a cross-component join remains unresolved; record each read in the source-read ledger |

Do not use older `architecture/**/*.md` collections as direct evidence for the
current version. They may be useful as semantic regression examples, but current
claims require current-version evidence.

## Evidence status

Every relationship in the ingress matrix must have one of these statuses:

- **Observed** — the relationship is directly present in structured data, a
  rendered manifest, or a source-backed component fact.
- **Derived** — the relationship follows from multiple compatible observed
  facts, such as an `HTTPRoute.backendRefs` Service whose selector targets a
  Deployment owned by another analyzed component.
- **Candidate** — the evidence strongly suggests a relationship, but an
  important join is not confirmed, such as an auth-check endpoint whose use as
  an Envoy `ext_authz` target is not visible.
- **Unresolved** — the relationship is required to explain the path, but the
  available evidence cannot establish it.
- **Confirmed-empty** — the relevant resource or relationship was explicitly
  inspected and found absent. Do not use this status for an unpopulated table or
  a component with no detected dependency edge.

Absence of a dependency edge, endpoint match, or component mention is not a
negative finding. Static inventories commonly omit relationships expressed by
generated manifests, dynamic controller code, service selectors, or runtime
configuration.

## Gateway inventory and centrality pass

Treat each Gateway or equivalent ingress frontend as a separate architectural
node. Do not group resources merely because they use Gateway API, Envoy, or the
same namespace. At minimum, inventory:

- Gateway name, namespace, GatewayClass, listeners, hostnames, and TLS mode;
- the operator, controller, manifest, or overlay that creates or configures it;
- attached HTTPRoutes, GRPCRoutes, VirtualServices, or legacy Routes;
- backend Services and the workloads reached through those Services;
- data-plane implementation and any gateway-specific filters or policies;
- the components and user-facing capabilities that depend on it; and
- whether it is central/shared, capability-specific, transitional, or unknown.

Calculate centrality from reverse consumers and route breadth, not from the
number of code-import dependencies. A Gateway is a central platform ingress
node when multiple independently owned components attach routes to it or when
it fronts multiple user-facing capabilities. Preserve that conclusion as
`derived` unless the Gateway and its route consumers are directly observed in
the same source-backed inventory.

Do not assume that an HTTPRoute belongs to the first Gateway mentioned by a
component. Resolve its `parentRefs`, configured gateway-name defaults, and
namespace. If a component's source constructs the route but the target Gateway
is configurable, record both the default and the configuration escape hatch.

## Mandatory source-resolution gate

Before drafting or writing `PLATFORM.md`, create a high-impact ingress join
queue. The queue must include every shared or central Gateway, every HTTPRoute
with a generic or missing `parentRef`, every Envoy/Istio filter, and every
gateway-level authentication or request-processing policy. For each queue row,
the agent must either resolve the relationship from current source or record a
source-read outcome showing why it remains `candidate` or `unresolved`.

Resolve the source checkout as follows:

1. Read `{platform_dir}/component-map.json` for the current platform version.
2. Map the producer and consumer component names to their `checkout_path`
   values. Prefer those exact paths; do not guess a repository from a name.
3. If a path is absolute, test that exact path with the available file tools.
   Generation environments commonly expose repository checkouts under
   `/data/checkouts`. If the path is unavailable, record that fact in the
   ledger and continue with an explicit unresolved result.
4. Use focused `Grep`/`Glob` searches and `Read` calls; do not read an entire
   repository. Search source and manifests for:

   - `Gateway`, `GatewayClass`, `HTTPRoute`, `parentRefs`, and gateway-name
     configuration;
   - `EnvoyFilter`, `ext_authz`, `ext_proc`, `DestinationRule`, and
     `AuthorizationPolicy`;
   - `data-science-gateway`, `kube-auth-proxy`, service names, ports, and
     auth-check paths such as `/oauth2/auth`.

For an Envoy authentication join, source inspection is complete only after
reading both sides:

- the producer/controller or manifest builder that creates the `EnvoyFilter`,
  including selector, filter type, cluster/service target, port, protocol,
  path, ordering, route scope, and conditional enablement; and
- the authentication service/proxy implementation or contract that receives
  the check, including endpoint behavior, expected credentials, returned
  headers/status, and backend identity handling.

“Dynamically generated” describes when the resource is materialized; it does
not justify stopping source analysis. Distinguish source-resolved wiring from
runtime-conditional activation. Only call a relationship `derived from source`
when the ledger names the source paths and the specific implementation facts
that support it.

The source-resolution gate is a write-blocking requirement. If the agent has
not attempted the producer and consumer reads for a high-impact row, it must
not write a final `candidate` or `unresolved` explanation for that row.

## Per-gateway authentication comprehension

Authentication must be modeled as a composition for each gateway, not as a
platform-wide list of mechanisms. For every gateway or ingress surface, trace
the request through these potentially independent layers:

```text
Gateway listener / data plane
  -> gateway policy (AuthPolicy, OAuth, OIDC, or equivalent)
  -> Envoy/Istio filters (ext_authz, ext_proc, Lua, TLS, mTLS)
  -> authentication service or auth-check endpoint
  -> pod-level proxy or sidecar (for example kube-rbac-proxy)
  -> application authentication and authorization
```

For each layer, identify the owner, input identity or credential, enforcement
point, output headers/tokens, failure behavior, and the routes to which it
applies. Explicitly distinguish:

- gateway-level `ext_authz` from a backend pod's `kube-rbac-proxy`;
- authentication from authorization and policy evaluation;
- TLS termination or re-encryption from user authentication; and
- a discovered auth endpoint from proof that a filter invokes that endpoint.

For the `data-science-gateway` pattern, look specifically for the complete
chain `EnvoyFilter -> ext_authz -> kube-auth-proxy`, including the exact filter
selector, target Service/port, auth-check path or protocol, route scope, and
whether the filter is conditional. The presence of `/oauth2/auth`, a
`kube-auth-proxy` deployment, or a generic EnvoyFilter watch is not sufficient
to mark this chain observed. If only some links are proven, retain the chain as
partly observed and mark the missing link `candidate` or `unresolved`.

Maintain a compact source-read ledger for every targeted repository read:

| Question | Component / checkout | Paths or search terms | Result | Status |
|----------|----------------------|-----------------------|--------|--------|
| What join was being tested? | Repository and component | Focused files or symbols | Relevant finding or no finding | observed / derived / candidate / unresolved |

The ledger may be summarized in the final provenance text, but the reasoning
must retain enough detail to distinguish a source-backed auth relationship
from an inference based only on component prose.

## Ingress path model

Normalize each distinct request path using this model. Not every path has every
stage, and a platform may have several paths active at once:

```text
external surface
  -> Gateway / Route / Ingress listener
  -> HTTPRoute / GRPCRoute / VirtualService routing
  -> Envoy / OpenShift router / other data plane
  -> gateway auth or policy layer
  -> Service
  -> Deployment / Pod / sidecar
  -> application endpoint or upstream
```

Record TLS termination, re-encryption, mTLS, header transformation, token
forwarding, authorization, and application-level authentication separately.
TLS termination does not establish authentication, and an authentication proxy
does not establish which routes invoke it.

## Relationship-resolution procedure

Resolve ingress relationships in this order:

1. **Inventory ingress surfaces.** Collect Gateway listeners, GatewayClasses,
   OpenShift Routes, Ingresses, HTTPRoutes, GRPCRoutes, VirtualServices, and
   external LoadBalancer or Route frontends. Record hostnames, listeners,
   namespaces, TLS modes, parent references, and whether a Route is primary,
   redirect-only, or an OAuth callback when that distinction is supported.

2. **Inventory gateways and their centrality.** Group each route by its resolved
   Gateway or equivalent frontend, identify the creator/owner, and calculate
   the reverse set of route-producing components and user-facing capabilities.
   Keep separate gateway rows even when they share a data plane or namespace.

3. **Resolve routing targets.** Follow `parentRefs`, `backendRefs`, Service
   names, ports, cross-namespace references, ReferenceGrants, and equivalent
   routing fields. Keep unresolved references explicit rather than replacing
   them with a guessed component.

4. **Resolve workload ownership.** Map each target Service to selectors,
   Deployments, StatefulSets, Pods, sidecars, container images, and component
   ownership. Use repository and image aliases cautiously; a name such as
   `odh-kube-auth-proxy` is not sufficient by itself to prove that it is the
   same implementation as `kube-auth-proxy`.

5. **Resolve data-plane filters and policies.** Inspect source-linked
   `EnvoyFilter`, `DestinationRule`, `AuthorizationPolicy`, `AuthPolicy`,
   `RateLimitPolicy`, and equivalent records. Distinguish `ext_authz` from
   `ext_proc`, and record the referenced service, port, path, protocol, filter
   ordering, and enablement condition when available.

6. **Match authentication contracts.** Compare the target of an auth filter or
   policy with endpoint and service contracts from the candidate authentication
   component. An endpoint named `/oauth2/auth` is evidence of an auth-check
   contract, but it is not by itself proof that Envoy calls that endpoint.

7. **Read both sides of unresolved joins.** If a relationship is important to
   the platform story but missing from the structured inventory, read the
   relevant producer (usually an operator/controller or manifest renderer) and
   consumer (usually the proxy, Service, or backend component). Record the
   question, expected signal, focused paths, outcome, and resulting status in
   the source-read ledger. For authentication, read both the filter producer
   and the auth-service/proxy contract before marking the chain observed. Do
   not read entire repositories solely to strengthen a plausible narrative.

## Required integration matrix

Build this matrix before writing the platform narrative. It may remain an
internal working artifact, but every material row must be reflected in the
appropriate `PLATFORM.md` sections.

| Gateway / ingress surface | Owner / creator | Routing resources | Data plane | Authentication composition | Backend consumers | Status | Evidence |
|--------------------------|----------------|---------------------|------------|--------------------------|------------------|--------|----------|
| Gateway name, namespace, listener, or Route host | Operator, controller, manifest, or overlay | HTTPRoute, GRPCRoute, VirtualService, Route, etc. | Envoy, router, or gateway | Policy -> filter -> auth service -> sidecar -> application auth | Services, workloads, and capabilities | observed/derived/candidate/unresolved | Source paths and resource identifiers |

Also build a gateway inventory for the final document:

| Gateway | Namespace / class | Creator / owner | Route consumers | Auth model | Centrality | Status |
|---------|------------------|-----------------|----------------|------------|----------|--------|
| Name | Namespace and GatewayClass | Component and source | Components and capabilities | Concise per-gateway chain | central/shared, capability-specific, transitional, or unknown | observed/derived/candidate/unresolved |

The `Auth model` cell must explain the enforcement chain, not merely say
"OAuth" or "Envoy." For example, it should identify whether the gateway uses
an Envoy `ext_authz` filter to call `kube-auth-proxy`, whether a policy engine
also participates, and whether the backend adds its own proxy or application
authorization.

For each row, answer:

- Where does external traffic enter?
- Which resource selects the backend?
- Which component creates or owns that resource?
- Where is TLS terminated and where is it re-established?
- Which mechanism authenticates and which authorizes?
- Does the request pass through a sidecar, gateway filter, policy engine, or
  application middleware?
- Which exact evidence is observed, and which connection is derived or still
  unresolved?

## Cross-component patterns to look for

Prioritize these joins because they are commonly invisible to code-import
dependency analysis:

- operator-generated Gateway, Route, HTTPRoute, EnvoyFilter, or DestinationRule
  resources targeting another component's Service;
- Envoy `ext_authz` filters calling a proxy's auth-check endpoint;
- Envoy `ext_proc` filters calling request-routing or payload-processing
  services;
- Gateway API `backendRefs` resolving through a Service to a component-owned
  workload;
- sidecar injection or programmatic Pod mutation that places an auth proxy in
  front of an application container;
- `AuthPolicy` or equivalent policy objects attached to an HTTPRoute;
- legacy OpenShift Routes coexisting with Gateway API resources, including
  redirect and OAuth callback Routes;
- shared proxy images with multiple binaries or modes, where the image name is
  not the same as the runtime role;
- version-specific transitions where an old Route path and a new Gateway path
  are both active.

Do not collapse gateway authentication, pod-level proxy authentication, and
application-level authorization into one generic "auth" pattern. They may have
different owners, credentials, failure behavior, and feature-assessment impact.

## Output requirements

Use the matrix to produce:

1. **Platform Overview:** a concise end-to-end ingress story, including major
   alternative paths and their status.
2. **Platform Network Architecture > Ingress Integration:** the completed
   ingress integration matrix, including the status of each cross-component
   relationship.
3. **Platform Network Architecture > Gateway Inventory:** one row per Gateway
   or equivalent frontend, including creator, route consumers, centrality, and
   authentication model.
4. **Platform Network Architecture > Ingress Analysis:** a free-form synthesis
   connecting the matrix into end-to-end request paths, explaining ownership,
   authentication composition, parallel ingress generations, and unresolved
   integration risks.
5. **Platform Network Architecture > Gateway Authentication:** a per-gateway
   explanation of identity flow, enforcement points, filter/policy composition,
   and backend-side auth. Keep `data-science-gateway`'s EnvoyFilter/
   `ext_authz`/`kube-auth-proxy` chain separate from pod-level proxies.
6. **Component Relationships:** dependency or runtime-integration edges for
   confirmed and derived cross-component relationships; candidate edges should
   remain visible when they materially affect platform behavior.
7. **Internal Service Mesh:** gateways, data planes, filter types, TLS paths,
   and the components using them.
8. **Authentication Mechanisms:** separate gateway auth, policy authorization,
   sidecar enforcement, and application auth, with enforcement points.
9. **Data Flows:** at least one end-to-end workflow for every materially distinct
   ingress path supported by the evidence.
10. **Platform Architectural Analysis:** unresolved joins, parallel ingress
   generations, ownership ambiguity, and operational or security implications.

When a feature assessment could be affected by an unresolved ingress join, state
the candidate relationship and the missing evidence explicitly. Do not let a
missing edge silently become a feature-support negative.

## Provenance

Preserve the evidence chain for each material relationship:

- ingress resource and source path;
- producer/controller and source path;
- filter or policy configuration and source path;
- target Service and workload ownership;
- authentication endpoint or policy contract;
- status and any unresolved join.

The final synthesis may be concise, but the source references must allow a
reviewer to distinguish a directly observed ingress configuration from a
cross-component inference.

For every high-impact row that remains `candidate` or `unresolved`, include the
source-read outcome in the final evidence or provenance text. It must state
which producer and consumer paths were inspected, what signal was sought, and
why the relationship could not be confirmed. Never write that a relationship
was derived from source unless those paths were actually read.
