workspace {
    model {
        user = person "Platform Engineer / Data Scientist" "Creates OGXServer CRs to deploy GenAI inference endpoints"

        ogxOperator = softwareSystem "OGX Kubernetes Operator" "Manages lifecycle of OGX server instances on Kubernetes/OpenShift" {
            reconciler = container "OGXServer Reconciler" "Single-controller reconciler managing all resources per OGXServer CR" "Go (controller-runtime)"
            webhook = container "Validating Webhook" "Validates OGXServer CRs on create/update (distribution names, provider IDs, adoption annotations)" "Go Admission Webhook"
            manifestPipeline = container "Manifest Pipeline" "Renders kustomize-based manifests with Go plugin chain (NamePrefix, Namespace, FieldMutator, NetworkPolicy)" "Go (kustomize/api)"
            configGenerator = container "Config Generator" "Resolves base config from OCI labels or ConfigMap, merges with CR spec to produce declarative config" "Go"
            legacyAdoption = container "Legacy Adoption Handler" "Migrates PVCs, Services, Ingresses from LlamaStackDistribution CRs to OGXServer CRs" "Go"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for all resource CRUD operations" "External"
        certManager = softwareSystem "cert-manager / service-serving-cert-signer" "Provisions TLS certificates for webhook serving" "External"
        ociRegistries = softwareSystem "OCI Container Registries" "quay.io, docker.io - host OGX distribution images" "External"
        odhPlatform = softwareSystem "ODH/RHOAI Platform" "Provides trusted CA bundles, monitoring CRDs, and SCC configuration" "Internal RHOAI"
        ogxInstances = softwareSystem "OGX Server Instances" "Deployed GenAI inference servers managed by the operator" "Managed Workload"
        monitoring = softwareSystem "Prometheus / Monitoring Stack" "Collects metrics via ServiceMonitor and evaluates PrometheusRules" "Internal RHOAI"

        user -> ogxOperator "Creates/updates OGXServer CRs via kubectl"
        ogxOperator -> k8sAPI "Watches CRs, applies resources via SSA, updates status" "HTTPS/443"
        ogxOperator -> ociRegistries "Fetches OCI image labels for base config resolution" "HTTPS/443"
        ogxOperator -> ogxInstances "Health checks and status polling" "HTTP/8321"
        ogxOperator -> odhPlatform "Reads trusted CA bundle, checks monitoring CRDs" "ConfigMap/CRD read"
        certManager -> ogxOperator "Provisions webhook TLS certificates" "Certificate/Secret"
        monitoring -> ogxOperator "Scrapes metrics via ServiceMonitor" "HTTP/8080"
        k8sAPI -> ogxOperator "Sends admission review requests to webhook" "HTTPS/443"

        reconciler -> manifestPipeline "Renders per-instance manifests"
        reconciler -> configGenerator "Generates declarative config ConfigMaps"
        reconciler -> legacyAdoption "Delegates legacy resource migration"
        reconciler -> webhook "Validates via admission webhook"
    }

    views {
        systemContext ogxOperator "SystemContext" {
            include *
            autoLayout
        }

        container ogxOperator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Managed Workload" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
