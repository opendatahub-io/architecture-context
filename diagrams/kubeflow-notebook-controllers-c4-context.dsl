workspace {
    model {
        user = person "Data Scientist" "Creates and manages Jupyter notebook instances for ML/data science workloads"

        kubeflowNotebooks = softwareSystem "Kubeflow Notebook Controllers" "Manages lifecycle of Jupyter notebook instances in Kubernetes with OAuth, networking, and integration support" {
            notebookController = container "notebook-controller" "Upstream Kubeflow controller for core notebook lifecycle management and culling" "Go Operator (controller-runtime)" {
                tags "ODH Component"
            }
            odhNotebookController = container "odh-notebook-controller" "ODH/RHOAI-specific extensions for OAuth, Routes, Gateway API, and integrations" "Go Operator (controller-runtime)" {
                tags "ODH Component"
            }
            webhookServer = container "notebook-webhook" "Validates and mutates Notebook custom resources during creation/update" "Go Admission Webhook" {
                tags "ODH Component"
            }
            cullingModule = container "notebook-controller-culler" "Monitors notebook activity and stops idle instances based on configurable thresholds" "Go Controller Module" {
                tags "ODH Component"
            }
        }

        # External Dependencies
        kubernetes = softwareSystem "Kubernetes API Server" "Container orchestration platform (OpenShift 4.19+)" "External" {
            tags "External"
        }
        istio = softwareSystem "Istio Service Mesh" "Optional service mesh for VirtualService-based networking and mTLS" "External Optional" {
            tags "External"
        }
        certManager = softwareSystem "cert-manager / OpenShift Service CA" "Certificate provisioning for webhook TLS certificates" "External" {
            tags "External"
        }

        # Internal ODH Dependencies
        dataSciencePipelines = softwareSystem "Data Science Pipelines Operator" "Provides pipeline runtime configuration and API endpoints for notebooks" "Internal ODH" {
            tags "Internal ODH"
        }
        openshiftOAuth = softwareSystem "OpenShift OAuth" "Provides user authentication for notebook web interfaces" "Internal ODH" {
            tags "Internal ODH"
        }
        gatewayAPI = softwareSystem "Gateway API" "Alternative ingress mechanism using Kubernetes Gateway API (HTTPRoute)" "Internal ODH" {
            tags "Internal ODH"
        }
        feast = softwareSystem "Feast Feature Store" "ML feature store integrated into notebooks via ConfigMap injection" "Internal ODH" {
            tags "Internal ODH"
        }

        # Monitoring and Observability
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal ODH" {
            tags "Internal ODH"
        }

        # External Services
        containerRegistry = softwareSystem "Container Registries" "Stores notebook container images (quay.io, registry.redhat.io)" "External" {
            tags "External"
        }

        # User Interactions
        user -> kubeflowNotebooks "Creates and manages Notebook custom resources via kubectl or Dashboard"

        # Controller Interactions
        kubeflowNotebooks -> kubernetes "Watches and reconciles Notebook CRs, creates StatefulSets, Services, Routes, NetworkPolicies, RBAC" "HTTPS/6443 (TLS 1.2+ Service Account Token)"
        notebookController -> kubernetes "Creates StatefulSet, Service, optionally VirtualService" "HTTPS/6443"
        odhNotebookController -> kubernetes "Creates Routes, HTTPRoutes, OAuth clients, NetworkPolicies, RBAC" "HTTPS/6443"
        webhookServer -> kubernetes "Validates and mutates Notebook CRs" "HTTPS/8443 (mTLS)"
        cullingModule -> kubernetes "Stops idle notebooks via Notebook CR updates" "HTTPS/6443"

        # Integration Points
        odhNotebookController -> dataSciencePipelines "Retrieves pipeline API endpoints and injects runtime configuration" "HTTP/8888"
        odhNotebookController -> openshiftOAuth "Creates OAuth clients for notebook authentication" "HTTPS/443 (TLS 1.2+)"
        odhNotebookController -> feast "Injects Feast configuration via ConfigMap" "Kubernetes API"
        notebookController -> istio "Creates VirtualServices for Istio-based ingress (optional)" "Kubernetes API"
        odhNotebookController -> gatewayAPI "Creates HTTPRoutes and ReferenceGrants for Gateway API ingress" "Kubernetes API"
        odhNotebookController -> prometheus "Exposes controller metrics" "HTTP/8080"
        webhookServer -> certManager "Obtains TLS certificates for webhook server" "Certificate API"

        # External Dependencies
        kubeflowNotebooks -> containerRegistry "Pulls notebook container images" "HTTPS/443 (TLS 1.2+ Pull Secrets)"

        # Notebook Access Flow
        user -> openshiftOAuth "Authenticates via OpenShift OAuth or Istio" "HTTPS/443"
        openshiftOAuth -> kubeflowNotebooks "Proxies authenticated requests to notebooks" "HTTP/80 (internal)"
    }

    views {
        systemContext kubeflowNotebooks "KubeflowNotebooksSystemContext" {
            include *
            autoLayout
        }

        container kubeflowNotebooks "KubeflowNotebooksContainers" {
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
                color #000000
            }
            element "ODH Component" {
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }

        themes default
    }
}
