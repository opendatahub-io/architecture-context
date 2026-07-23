workspace {
    model {
        user = person "Data Scientist / Developer" "Creates and manages interactive development environments (JupyterLab, RStudio, VS Code)"
        admin = person "Platform Administrator" "Configures WorkspaceKind templates and manages platform settings"

        workbenches = softwareSystem "Workbenches (Kubeflow Notebooks v2)" "Kubernetes operator, REST API, and web UI for managing interactive development environments" {
            controller = container "workspaces-controller" "Reconciles Workspace CRs into StatefulSets, Services, and VirtualServices; hosts validating webhooks" "Go Operator (controller-runtime)" "Operator"
            backend = container "workspaces-backend" "REST API for workspace and infrastructure CRUD with Kubernetes-native auth via SubjectAccessReview" "Go REST API (httprouter)" "API"
            frontend = container "workspaces-frontend" "Web UI for workspace lifecycle management and WorkspaceKind administration" "React 18 + PatternFly 6 (nginx)" "WebApp"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for traffic management, mTLS, and authorization" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        kubeflowGateway = softwareSystem "Kubeflow Gateway" "Shared Istio Gateway for Kubeflow/RHOAI ingress" "Internal Platform"

        # User interactions
        user -> workbenches "Creates, pauses, resumes, deletes Workspaces via web UI"
        admin -> workbenches "Configures WorkspaceKind templates (images, resources, IDEs)"

        # Frontend → Backend
        frontend -> backend "REST API calls" "HTTP/4000 via Istio mTLS"

        # Backend → Kubernetes
        backend -> kubernetes "CRUD Workspaces, WorkspaceKinds, Namespaces, Secrets, PVCs, StorageClasses" "HTTPS/6443"
        backend -> kubernetes "SubjectAccessReview for user authorization" "HTTPS/6443"

        # Controller → Kubernetes
        controller -> kubernetes "Watch Workspace/WorkspaceKind CRDs; Create StatefulSets, Services, VirtualServices" "HTTPS/6443"

        # External integrations
        workbenches -> istio "VirtualService-based workspace routing and mTLS enforcement"
        workbenches -> certManager "TLS certificate for webhook server" "Certificate CR"
        workbenches -> prometheus "Exposes controller metrics" "HTTP/8080"
        istio -> kubeflowGateway "Routes external traffic to workbenches services" "HTTPS/443"

        # User → Workspace pods
        user -> istio "Connects to running workspace IDE (JupyterLab/RStudio/VS Code)" "HTTPS/443"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "API" {
                background #4a90e2
                color #ffffff
            }
            element "WebApp" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
        }
    }
}
