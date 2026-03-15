workspace {
    model {
        user = person "Data Scientist" "Creates and manages Jupyter notebooks for ML development and experimentation"

        odhNotebookController = softwareSystem "ODH Notebook Controller" "Extends Kubeflow Notebook Controller with OpenShift-specific ingress and OAuth authentication capabilities" {
            controller = container "OpenshiftNotebookReconciler" "Reconciles Notebook CRs to create OpenShift Routes, ServiceAccounts, Secrets, ConfigMaps, and NetworkPolicies" "Go Controller"
            webhook = container "NotebookWebhook" "Injects OAuth proxy sidecar and reconciliation lock annotations into Notebook pods during admission" "Go Mutating Webhook"
            manager = container "Manager Deployment" "Hosts the controller and webhook server with health and metrics endpoints" "Go Deployment"

            controller -> manager "hosted by"
            webhook -> manager "hosted by"
        }

        kubeflowController = softwareSystem "Kubeflow Notebook Controller" "Provides Notebook CRD and base notebook reconciliation logic" "External - Upstream Kubeflow"
        openshiftRouter = softwareSystem "OpenShift Route API" "Enables external ingress via OpenShift router with automatic TLS edge termination" "External - OpenShift"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "Provides enterprise SSO authentication using OpenShift's built-in OAuth server" "External - OpenShift"
        serviceCA = softwareSystem "OpenShift Service CA Operator" "Automatically provisions TLS certificates via service annotations with auto-rotation" "Internal - OpenShift"
        k8sAPI = softwareSystem "Kubernetes API Server" "Provides resource management, RBAC authorization, and Subject Access Review (SAR)" "External - Kubernetes"
        oauthProxy = softwareSystem "OpenShift OAuth Proxy" "Container image providing OAuth authentication sidecar for notebook access" "External - OpenShift"

        notebookPod = softwareSystem "Notebook Pod" "JupyterLab instance with optional OAuth proxy sidecar for authenticated access" "Runtime"

        user -> odhNotebookController "Creates Notebook CR via kubectl"
        user -> notebookPod "Accesses JupyterLab UI via browser" "HTTPS/443"

        odhNotebookController -> kubeflowController "Watches Notebook CRs created by upstream controller" "Kubernetes Watch API"
        odhNotebookController -> openshiftRouter "Creates Routes for external access" "Route API"
        odhNotebookController -> k8sAPI "Creates ServiceAccounts, Secrets, ConfigMaps, NetworkPolicies" "HTTPS/6443"
        odhNotebookController -> serviceCA "Uses for webhook and OAuth proxy certificate provisioning" "Service Annotation"

        k8sAPI -> webhook "Calls mutating webhook during Notebook admission" "HTTPS/8443"

        notebookPod -> openshiftRouter "Routes external traffic to OAuth proxy" "HTTPS/443"
        notebookPod -> openshiftOAuth "Authenticates users via OAuth flow" "HTTPS/443 mTLS"
        notebookPod -> k8sAPI "Authorizes access via Subject Access Review" "HTTPS/6443"
        notebookPod -> oauthProxy "Uses OAuth proxy sidecar container (when enabled)" "Container Image"
    }

    views {
        systemContext odhNotebookController "SystemContext" {
            include *
            autoLayout
        }

        container odhNotebookController "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External - Upstream Kubeflow" {
                background #999999
                color #ffffff
            }
            element "External - OpenShift" {
                background #ee0000
                color #ffffff
            }
            element "External - Kubernetes" {
                background #326ce5
                color #ffffff
            }
            element "Internal - OpenShift" {
                background #7ed321
                color #000000
            }
            element "Runtime" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}
