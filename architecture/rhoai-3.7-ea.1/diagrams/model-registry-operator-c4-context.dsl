workspace "model-registry-operator" "RHOAI 3.7-ea.1 Model Registry / AIHub module operator" {
    model {
        user = person "Data Scientist / ML Engineer" "Registers models and browses the model catalog"
        admin = person "Platform Admin" "Enables the AIHub module via the DataScienceCluster"

        mro = softwareSystem "Model Registry Operator (AIHub module)" "One image, three operators: AIHub installs child operators that deploy per-namespace Model Registry services and a shared Model Catalog" {
            aihub = container "aihub-controller-manager" "Reconciles AIHub singleton; renders and SSA-applies the child operator bundle; creates instances namespace and Catalog CR; aggregates readiness" "Go Operator (manager aihub)"
            mrop = container "model-registry-operator-controller-manager" "Reconciles ModelRegistry CRs; serves mutating, validating and conversion webhooks on 9443" "Go Operator (manager)"
            catop = container "catalog-controller-manager" "Reconciles singleton Catalog CR; manages catalog data ImageStreams; serves Catalog validating webhook on 9443" "Go Operator (manager catalog)"
            registry = container "Model Registry instance" "rest-container (8080) behind kube-rbac-proxy (8443), one per ModelRegistry CR" "Model Registry REST + kube-rbac-proxy"
            registryDb = container "Registry PostgreSQL" "Optional auto-provisioned PostgreSQL 16 per registry" "PostgreSQL 16" "Database"
            catalog = container "model-catalog" "Shared model catalog service behind kube-rbac-proxy (8443)" "Model Registry (catalog mode) + kube-rbac-proxy"
            catalogDb = container "model-catalog-postgres" "PVC-backed PostgreSQL 16 for catalog" "PostgreSQL 16" "Database"
        }

        rhods = softwareSystem "rhods-operator" "RHOAI platform operator; deploys overlays/aihub and creates the AIHub CR from DSC" "Internal RHOAI"
        k8s = softwareSystem "Kubernetes / OpenShift API" "API server, TokenReview/SAR, Routes, Groups, ImageStreams, config APIs" "External"
        gateway = softwareSystem "data-science-gateway" "Gateway API ingress in openshift-ingress" "Internal RHOAI"
        dashboard = softwareSystem "RHOAI Dashboard (model-registry-ui)" "Registry and catalog UI" "Internal RHOAI"
        automl = softwareSystem "automl-ui" "Accesses registries from generated namespaces" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Scrapes operator metrics via ServiceMonitor" "External"
        serviceCa = softwareSystem "OpenShift service-ca" "Issues serving certs and injects CA bundles" "External"
        extDb = softwareSystem "User PostgreSQL / MySQL" "External registry metadata store" "External"
        rhRegistry = softwareSystem "registry.redhat.io" "ai-hub-catalog-rhel9 catalog data images" "External"
        objectStores = softwareSystem "Hugging Face / S3 / OCI" "Sources and destinations for async model upload Jobs" "External"

        admin -> rhods "Enables aiHub in DataScienceCluster"
        rhods -> aihub "Deploys and creates AIHub CR; reads AIHubReady" "Kubernetes API 6443"
        aihub -> k8s "SSA CRDs, webhooks, RBAC, Deployments, NetworkPolicies, Templates" "HTTPS/6443"
        aihub -> mrop "Installs and stamps images / namespaces"
        aihub -> catop "Installs; creates Catalog CR"
        mrop -> registry "Deploys per ModelRegistry"
        mrop -> registryDb "Optionally provisions"
        catop -> catalog "Deploys"
        catop -> catalogDb "Provisions"
        k8s -> mrop "Admission + conversion webhooks" "HTTPS 443->9443"
        k8s -> catop "Catalog validating webhook" "HTTPS 443->9443"
        mrop -> k8s "Reconciles owned resources" "HTTPS/6443"
        catop -> k8s "Reconciles owned resources, ImageStreams" "HTTPS/6443"

        user -> gateway "Calls /model-registry/{name}/ and /catalog/" "HTTPS/443 Bearer"
        user -> dashboard "Browses registries and catalog"
        dashboard -> gateway "Registry/catalog API" "HTTPS/443"
        automl -> registry "Registry API" "HTTPS/8443"
        gateway -> registry "Forwards to kube-rbac-proxy" "HTTPS/8443"
        gateway -> catalog "Forwards to kube-rbac-proxy" "HTTPS/8443"
        registry -> k8s "TokenReview + SubjectAccessReview" "HTTPS/6443"
        catalog -> k8s "TokenReview + SubjectAccessReview" "HTTPS/6443"
        registry -> registryDb "Stores metadata" "PostgreSQL/5432 plaintext"
        registry -> extDb "Stores metadata" "PostgreSQL 5432 / MySQL 3306, optional TLS"
        catalog -> catalogDb "Stores catalog" "PostgreSQL/5432 plaintext"
        k8s -> rhRegistry "ImageStream scheduled import" "HTTPS/443"
        aihub -> objectStores "Async upload Job templates (Jobs connect)" "HTTPS/443"
        prometheus -> aihub "Scrapes /metrics" "HTTPS/8443"
        prometheus -> mrop "Scrapes /metrics" "HTTPS/8443"
        serviceCa -> mro "Serving certs for webhooks, metrics, kube-rbac-proxy"
    }

    views {
        systemContext mro "SystemContext" {
            include *
            autoLayout
        }

        container mro "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Database" {
                shape Cylinder
            }
            element "External" {
                background #999999
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
