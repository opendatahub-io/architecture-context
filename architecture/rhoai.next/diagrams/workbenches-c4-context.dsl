workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages interactive development environments (JupyterLab, RStudio, VS Code)"
        platformAdmin = person "Platform Admin" "Manages WorkspaceKind templates and platform configuration"

        workbenches = softwareSystem "Workbenches" "Kubeflow Notebooks v2 - manages interactive development environments on Kubernetes through a three-tier architecture" {
            controller = container "workspaces-controller" "Reconciles Workspace and WorkspaceKind CRDs into StatefulSets, Services, ingress resources, and RBAC bindings" "Go Controller (controller-runtime)"
            webhook = container "Webhook Server" "Validates Workspace and WorkspaceKind resources; handles CRD conversion" "Go (admission webhooks, port 9443)"
            backend = container "workspaces-backend" "REST API for workspace management with per-user authentication and authorization" "Go API Server (httprouter, port 4000)"
            frontend = container "workspaces-frontend" "Web UI for managing workspaces" "React SPA (nginx, port 8080)"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource operations, authentication, and authorization" "Platform"
        gatewayAPI = softwareSystem "Gateway API" "data-science-gateway in openshift-ingress for per-workspace HTTPRoute-based ingress" "Platform"
        istio = softwareSystem "Istio" "Service mesh for per-workspace VirtualService-based ingress (alternative to Gateway API)" "External"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Authentication sidecar injected into workspace pods (Gateway API mode)" "Platform"
        metricsAPI = softwareSystem "Kubernetes Metrics API" "Pod resource metrics for workspace monitoring" "Platform"
        openShiftAPI = softwareSystem "OpenShift APIServer CR" "TLS security profile source for dynamic TLS configuration" "Platform"

        # User relationships
        dataScientist -> frontend "Manages workspaces via browser"
        platformAdmin -> backend "Manages WorkspaceKinds via API"

        # Internal relationships
        frontend -> backend "REST API calls" "HTTP/4000"
        backend -> kubernetesAPI "TokenReview, SubjectAccessReview, resource CRUD" "HTTPS/6443"
        controller -> kubernetesAPI "Watch/reconcile Workspaces, create StatefulSets, Services, etc." "HTTPS/6443"
        controller -> openShiftAPI "Read TLS security profile" "HTTPS/6443"
        kubernetesAPI -> webhook "Admission webhook calls" "HTTPS/9443"

        # External relationships
        controller -> gatewayAPI "Create per-workspace HTTPRoutes" "HTTPS/6443"
        controller -> istio "Create per-workspace VirtualServices" "HTTPS/6443"
        controller -> kubeRBACProxy "Inject sidecar into workspace pods" "Container spec"
        backend -> metricsAPI "Query pod resource metrics" "HTTPS/6443"
    }

    views {
        systemContext workbenches "SystemContext" {
            include *
            autoLayout
        }

        container workbenches "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Platform" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
        }
    }
}
