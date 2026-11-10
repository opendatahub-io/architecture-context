workspace "workbenches" "Kubeflow Notebooks v2 Workspaces controller - RHOAI 3.7-ea.1" {
    model {
        user = person "Data Scientist" "Creates Workspaces and uses browser IDEs"
        admin = person "Platform Admin" "Defines cluster-scoped WorkspaceKind templates"

        workbenches = softwareSystem "workbenches" "Reconciles Workspace/WorkspaceKind CRDs into per-user IDE StatefulSets exposed via Gateway API behind kube-rbac-proxy" {
            controller = container "workspaces-controller" "Single manager: WorkspaceReconciler, WorkspaceKindReconciler, TLS ProfileWatcher, activity prober; odh-workbenches-controller-rhel9" "Go controller-runtime"
            webhooks = container "Validating webhooks" "vworkspace / vworkspacekind on 9443/TCP HTTPS, failurePolicy Fail" "Go"
            workspacePod = container "Workspace pod" "Per-Workspace StatefulSet: IDE container (JupyterLab / code-server / RStudio), app port HTTP" "StatefulSet"
            proxy = container "kube-rbac-proxy sidecar" "8443/TCP HTTPS; SAR get workspaces/name; forwards X-Auth-Request-User/Groups" "Sidecar"
            backend = container "backend" "Upstream-only REST API /api/v1 on 4000/TCP; not built downstream" "Go" "Upstream"
            frontend = container "frontend" "Upstream-only React UI on nginx 8080/TCP; not built downstream" "TypeScript" "Upstream"
        }

        k8s = softwareSystem "Kubernetes API" "API server 6443/TCP" "External"
        gateway = softwareSystem "data-science-gateway" "Gateway API entry point in openshift-ingress (rhods-operator)" "Internal RHOAI"
        operator = softwareSystem "workbenches-operator" "Deploys overlays/gateway, rewrites namespace and image" "Internal RHOAI"
        serviceCA = softwareSystem "OpenShift Service CA" "Serving certs and CA bundle injection" "Internal RHOAI"
        apiserverCfg = softwareSystem "OpenShift APIServer config" "Cluster tlsSecurityProfile and tlsAdherence" "Internal RHOAI"
        prometheus = softwareSystem "OpenShift Monitoring" "Prometheus via ServiceMonitor" "Internal RHOAI"
        dashboard = softwareSystem "odh-dashboard" "Consumes workspace resources and RBAC (inferred)" "Internal RHOAI"
        images = softwareSystem "Workbench images" "IDE images referenced by WorkspaceKind imageConfigs" "Internal RHOAI"
        istio = softwareSystem "Istio" "VirtualService ingress, upstream mode only" "External"

        user -> gateway "Opens /workspace/connect/ns/name/port/" "HTTPS/443 TLS 1.2+, OAuth/OIDC"
        user -> k8s "Creates Workspace CRs" "HTTPS/6443"
        admin -> k8s "Creates WorkspaceKind CRs" "HTTPS/6443"
        dashboard -> k8s "Manages Workspaces" "HTTPS/6443"
        gateway -> proxy "Routes via HTTPRoute ws-ns-name" "HTTPS/8443 Service CA TLS, Bearer"
        proxy -> k8s "TokenReview + SubjectAccessReview" "HTTPS/6443"
        proxy -> workspacePod "Forwards authorized traffic" "HTTP loopback"
        k8s -> webhooks "Admission review" "HTTPS 443 to 9443"
        controller -> k8s "CRUD, watches, pods/exec" "HTTPS/6443 SA token"
        controller -> workspacePod "Jupyter /api/status activity probe" "HTTP plaintext, pod IP"
        controller -> gateway "Creates HTTPRoutes with parentRef" "via Kubernetes API"
        controller -> apiserverCfg "Reads TLS profile" "get/watch"
        serviceCA -> workbenches "Issues serving certs for webhook, metrics, proxy"
        prometheus -> controller "Scrapes /metrics" "HTTPS/8443 Bearer"
        operator -> workbenches "Deploys controller manifests"
        workspacePod -> images "Runs IDE images"
        controller -> istio "Creates VirtualServices (upstream only)"
        frontend -> backend "REST calls" "HTTP"
        backend -> k8s "Workspace CRUD, TokenReview, SAR" "HTTPS/6443"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Upstream" {
                background #e8e8e8
                color #333333
            }
        }
    }
}
