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

**Common mistake #3:** Classifying all DSC-managed components as `payload_component`

**Why this is wrong:**
- Components with a field in the DataScienceCluster `Components` struct are user-togglable (Managed/Removed)
- These are `optional_platform`, not `payload_component`
- `payload_component` is for repos that provide container images deployed BY optional_platform operators — they have no DSC toggle
- Example: `kserve` has a DSC field → `optional_platform`. `vllm` is deployed by `odh-model-controller` → `payload_component`

**Common mistake #4:** Classifying every repo with manifests as `type: "operator"`

**Why this is wrong:**
- A repo that ships notebook images (`notebooks-downstream`) is not an operator — it's an `asset`
- A repo that provides a model server (`vllm`) is not an operator — it's a `service`
- A repo that defines shared CRDs (`kubeflow`) is not an operator — it's a `shared_library`
- Check for actual controller/reconciler code before using `type: "operator"` (see Step 5c)

**Common mistake #5:** Including build infrastructure as components

**Why this is wrong:**
- `RHOAI-Build-Config` contains build configs, catalog definitions, and image lists — it's NOT a shipped component
- `must-gather` is a diagnostic tool, not a platform service
- `konflux-central` is CI/CD infrastructure
- These should be excluded, not included as `payload_component`

**Rule of thumb:**
- If it's in the same GitHub org AND used by 2+ components → INCLUDE as `type: "shared_library"`
- If it's external BUT defines CRDs/APIs your platform implements → INCLUDE as `type: "api_specification"`
- If it's external AND just a utility you call → EXCLUDE (django, postgres, redis)
- If it's build/CI infrastructure or diagnostic tooling → EXCLUDE

**Example distinction:**
- ✅ Include: `kubeflow` (first-party fork, used by notebooks + training-operator + trainer)
- ✅ Include: `ml-metadata` (shared library, used by data-science-pipelines + model-registry)
- ✅ Include: `odh-cli` (shipped CLI tool starting with RHOAI 3.3+)
- ❌ Exclude: `RHOAI-Build-Config` (build infrastructure, not a deployed component)
- ❌ Exclude: `must-gather` (diagnostic support tool)
- ❌ Exclude: `konflux-central` (CI/CD infrastructure)

**Common mistake #6:** Excluding repos matched by RELATED_IMAGE or catalog parsing

**Why this is wrong:**
- If `parse_related_images.py` matches a repo, the operator deploys that repo's container image as an operand
- If `parse_catalog_images.py` matches a repo, the image is in the OLM catalog's `relatedImages` — it ships in the product
- Reclassifying these as "infrastructure_utility", "covered_by_X", or "deprecated" contradicts the authoritative signal
- Example: `kube-rbac-proxy` was matched by RELATED_IMAGE (5 consumers!) but excluded as "infrastructure_utility" — it's a security-critical sidecar proxy that runs in every component

**Rule:** Script matches are binding. If the script says it's shipped, include it. The only exception is build infrastructure repos like `RHOAI-Build-Config`.
