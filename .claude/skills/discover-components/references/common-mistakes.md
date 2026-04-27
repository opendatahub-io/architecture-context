# Common Mistakes

## Critical: Don't Exclude Shared Libraries or API Contracts!

**Common mistake #1:** Excluding repos because they're "just dependencies"

**Why this is wrong:**
- First-party shared libraries (like django-ansible-base) are architecturally critical
- They're YOUR code, not third-party packages
- Security vulnerabilities in shared libraries impact ALL consumers
- Understanding the platform requires understanding shared foundations
- Architecture reviews need to see the full dependency picture

**Common mistake #2:** Excluding external repos because they're "third-party upstream"

**Why this is wrong for API specs:**
- Some external repos define the API contracts your platform implements
- Your controllers/reconcilers are structured around their types
- Excluding them makes your architecture diagrams incomplete — the CRDs your control plane reconciles just vanish
- Understanding *what* your platform implements is as important as understanding *how*

**Common mistake #3:** Marking an operator as optional because ANY manifest has a capability annotation

**Why this is wrong:**
- A capability annotation on a dashboard means "only create this dashboard if Console is enabled"
- A capability annotation on a credential request means "only create this credential if CloudCredential is enabled"
- Neither of these means the OPERATOR is optional
- Only the Deployment manifest determines the operator's tier
- Example: `cluster-kube-apiserver-operator` has `capability.openshift.io/name: Console` on dashboards but is absolutely core — without it there's no API server

**Common mistake #4:** Classifying every repo with manifests as `type: "operator"`

**Why this is wrong:**
- A repo that ships GPG signing keys (`cluster-update-keys`) is not an operator
- A repo that ships branding assets (`origin-branding`) is not an operator
- A repo that provides a base container image (`driver-toolkit`) is not an operator
- Check for actual controller/reconciler code before using `type: "operator"` (see Step 5c)

**Common mistake #5:** Excluding bootstrap components that lack release annotations

**Why this is wrong:**
- CVO is the thing that reads release annotations — it can't annotate itself
- The installer bootstraps the cluster before CVO exists
- These are the most architecturally significant components and must be `core_platform`

**Rule of thumb:**
- If it's in the same GitHub org AND used by 2+ components → INCLUDE as `type: "shared_library"`
- If it's external BUT defines CRDs/APIs your platform implements → INCLUDE as `type: "api_specification"`
- If it's external AND just a utility you call → EXCLUDE (django, postgres, redis)

**Example distinction:**
- ✅ Include: `ansible/django-ansible-base` (first-party, used by AWX + EDA + Hub)
- ✅ Include: `kubernetes-sigs/gateway-api` (external, but Istio's control plane implements its CRDs)
- ✅ Include: `cluster-version-operator` (core_platform, even without release annotations — it's the reconciler)
- ❌ Exclude: `django/django` (third-party utility, not in ansible org)
- ❌ Exclude: `postgres` (infrastructure, third-party)
- ❌ Exclude: `envoyproxy/go-control-plane` (third-party library you call, not a contract you implement)
