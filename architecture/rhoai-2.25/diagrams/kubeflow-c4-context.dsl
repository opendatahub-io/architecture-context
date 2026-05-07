workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Jupyter notebook workbenches for ML experimentation"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and notebook controller configuration"

        kubeflowNotebooks = softwareSystem "Kubeflow Notebook Controllers" "Manages the lifecycle of Jupyter Notebook workspaces (workbenches) on OpenShift, including pod orchestration, OAuth authentication, network isolation, and idle resource reclamation" {
            kfNotebookController = container "kf-notebook-controller" "Core notebook lifecycle: StatefulSet, Service, VirtualService management, idle culling" "Go Operator (controller-runtime v0.21.0)" {
                notebookReconciler = component "NotebookReconciler" "Watches Notebook CRs, reconciles StatefulSets (replicas=1), Services, and optional VirtualServices" "controller-runtime Reconciler"
                cullingReconciler = component "CullingReconciler" "Monitors Jupyter kernel/terminal activity via HTTP API, stops idle notebooks by setting replicas=0" "controller-runtime Reconciler"
                reconcileHelper = component "reconcilehelper" "Shared reconciliation utilities for Deployments, Services, StatefulSets, VirtualServices" "Go Library"
            }
            odhNotebookController = container "odh-notebook-controller" "OpenShift integration: OAuth proxy injection, Routes, NetworkPolicies, certificate management, DSPA integration" "Go Operator (controller-runtime v0.21.0)" {
                odhReconciler = component "ODH NotebookReconciler" "Watches Notebook CRs, creates Routes, OAuthClients, NetworkPolicies, Secrets, CA bundles" "controller-runtime Reconciler"
                webhookServer = component "Mutating Webhook" "Intercepts Notebook CREATE/UPDATE, injects oauth-proxy sidecar, manages update-pending deferrals" "Admission Webhook (8443/TCP)"
                oauthManager = component "OAuth Manager" "Creates OAuthClient, oauth-proxy config, cookie/client secrets per notebook" "Go Controller"
                routeManager = component "Route Manager" "Creates OpenShift Routes with edge or re-encrypt TLS termination" "Go Controller"
                networkManager = component "Network Manager" "Creates per-notebook NetworkPolicies for workload isolation" "Go Controller"
                certManager = component "Certificate Manager" "Aggregates CA bundles from kube-root-ca.crt, openshift-service-ca.crt, odh-trusted-ca-bundle" "Go Controller"
                dspaIntegration = component "DSPA Integration" "Discovers pipeline endpoint, S3 credentials for Elyra notebook integration" "Go Controller"
            }
        }

        // External Systems
        k8sAPI = softwareSystem "Kubernetes API Server" "Central API server for all cluster resource operations" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "OpenShift identity provider for user authentication" "External"
        openshiftRouter = softwareSystem "OpenShift Ingress Controller" "Assigns hostnames, terminates TLS for Routes" "External"
        openshiftServiceCA = softwareSystem "OpenShift Service CA" "Auto-provisions TLS certificates via annotations" "External"
        istio = softwareSystem "Istio Service Mesh" "Optional service mesh for traffic management and mTLS" "External Optional"

        // Internal ODH Systems
        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing RHOAI resources including notebook workbenches" "Internal ODH"
        dspOperator = softwareSystem "Data Science Pipelines Operator" "Manages ML pipeline infrastructure, provides DSPA CRDs" "Internal ODH"

        // Relationships - Users
        dataScientist -> dashboard "Creates/manages notebook workbenches via" "HTTPS"
        dataScientist -> kubeflowNotebooks "Accesses notebook via OpenShift Route" "HTTPS/443"
        platformAdmin -> kubeflowNotebooks "Configures culling, OAuth settings" "kubectl/HTTPS"

        // Relationships - Dashboard
        dashboard -> kubeflowNotebooks "Creates Notebook CRs" "HTTPS/6443"

        // Relationships - Controllers to K8s API
        kubeflowNotebooks -> k8sAPI "CRD watches, StatefulSet/Service/Secret/ConfigMap CRUD" "HTTPS/6443"
        kubeflowNotebooks -> openshiftOAuth "OAuthClient CRUD, token validation" "HTTPS/443"
        kubeflowNotebooks -> openshiftRouter "Route creation for notebook access" "HTTPS/6443"
        kubeflowNotebooks -> openshiftServiceCA "TLS cert auto-provisioning via annotations" "Annotation-triggered"
        kubeflowNotebooks -> istio "VirtualService CRUD when USE_ISTIO=true" "HTTPS/6443"
        kubeflowNotebooks -> dspOperator "Discovers DSPA endpoint, S3 creds for Elyra" "HTTPS/6443"
        dashboard -> kubeflowNotebooks "Provides public API URL for Elyra pipeline config" "CRD Read"
    }

    views {
        systemContext kubeflowNotebooks "SystemContext" {
            include *
            autoLayout
        }

        container kubeflowNotebooks "Containers" {
            include *
            autoLayout
        }

        component kfNotebookController "KFComponents" {
            include *
            autoLayout
        }

        component odhNotebookController "ODHComponents" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Optional" {
                background #999999
                color #ffffff
                opacity 50
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
