workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys OGX inference server instances via OGXServer CRs"
        platformAdmin = person "Platform Admin" "Manages ODH/RHOAI platform, enables OGX component"

        ogxOperator = softwareSystem "OGX K8s Operator" "Kubernetes operator that deploys and manages OGX inference server instances via the OGXServer custom resource" {
            manager = container "OGX Operator Manager" "Reconciles OGXServer CRs into Deployments, Services, PVCs, NetworkPolicies, Ingresses, HPAs, PDBs; manages config generation, legacy adoption, and status reporting" "Go Operator (controller-runtime)" "Primary"
            webhook = container "Validating Webhook" "Validates OGXServer create/update: distribution name, provider IDs, model refs, adoption annotations" "Go (controller-runtime webhook)" "Webhook"
            configGen = container "Config Generator" "Generates config.yaml from declared providers; resolves base config from OCI labels or ConfigMap; content-hash naming, immutable ConfigMaps" "Go (kustomize pipeline)"
            legacyAdoption = container "Legacy Adoption System" "Migrates LlamaStackDistribution resources to OGXServer; handles RWO PVC constraints, Service/Ingress transfer" "Go"
        }

        ogxModule = softwareSystem "OGX Module Operator" "ODH/RHOAI platform module that bridges the platform orchestrator with the OGX operator; currently scaffolded" "Scaffold" {
            moduleController = container "Module Controller" "Watches OGX CR from platform operator, deploys OGX operator kustomize manifests" "Go Operator (controller-runtime)" "Scaffold"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API server for CR watches, resource CRUD, leader election, webhook calls" "External"
        ociRegistry = softwareSystem "OCI Image Registry" "Container image registries hosting OGX distribution images; OCI labels used for base config resolution" "External"
        certProvider = softwareSystem "Certificate Provider" "cert-manager or OpenShift service-serving-cert-signer for webhook TLS certificates" "External"
        prometheusOp = softwareSystem "Prometheus Operator" "Optional: operator creates ServiceMonitor/PrometheusRule if CRDs detected" "Internal ODH"
        platformOperator = softwareSystem "ODH/RHOAI Platform Operator" "Creates OGX CR to enable the component; ogx-module watches this CR" "Internal ODH"
        ogxServer = softwareSystem "OGX Server Instances" "Managed OGX inference server workloads running in user namespaces" "Managed Workload"

        # Relationships
        dataScientist -> ogxOperator "Creates OGXServer CR via kubectl" "HTTPS/6443"
        platformAdmin -> platformOperator "Enables OGX component"
        platformOperator -> ogxModule "Creates OGX CR" "CRD (components.platform.opendatahub.io/OGX)"
        ogxModule -> ogxOperator "Deploys operator kustomize manifests"

        ogxOperator -> k8sAPI "CR watches, resource CRUD, leader election" "HTTPS/6443 TLS 1.2+ SA token"
        ogxOperator -> ociRegistry "Fetches OCI labels for base config resolution" "HTTPS/443 TLS 1.2+"
        ogxOperator -> certProvider "Webhook TLS certificate provisioning"
        ogxOperator -> prometheusOp "Creates ServiceMonitor/PrometheusRule if CRDs exist" "CRD"
        ogxOperator -> ogxServer "Creates Deployments, polls health" "HTTP/8321"

        k8sAPI -> ogxOperator "Admission webhook calls" "HTTPS/9443 TLS"

        # Internal container relationships
        manager -> webhook "Registers webhook handler"
        manager -> configGen "Generates config.yaml for each OGXServer"
        manager -> legacyAdoption "Handles LlamaStackDistribution migration"
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
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Managed Workload" {
                background #4a90e2
                color #ffffff
            }
            element "Scaffold" {
                background #f5a623
                color #ffffff
            }
            element "Primary" {
                background #4a90e2
                color #ffffff
            }
            element "Webhook" {
                background #e74c3c
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
