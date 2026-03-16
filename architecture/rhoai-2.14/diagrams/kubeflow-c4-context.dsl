workspace {
    model {
        user = person "Data Scientist" "Creates and accesses Jupyter notebooks for data analysis and ML experimentation"
        admin = person "Platform Administrator" "Manages ODH platform and configures notebook controller"

        odhNotebookController = softwareSystem "ODH Notebook Controller" "Extends Kubeflow Notebook Controller with OpenShift-specific features: Route-based ingress, OAuth proxy authentication, and network policy management" {
            reconciler = container "OpenshiftNotebookReconciler" "Reconciles Notebook CRs and creates OpenShift resources" "Go Controller (Kubebuilder)" {
                tags "Controller"
            }
            webhook = container "NotebookWebhook" "Mutating admission webhook that injects OAuth proxy sidecar" "Go Webhook Server" {
                tags "Webhook"
            }
            managerDeployment = container "Manager Deployment" "Runs controller and webhook server" "Kubernetes Pod" {
                tags "Pod"
            }
        }

        kubeflowController = softwareSystem "Kubeflow Notebook Controller" "Creates and manages underlying StatefulSets and Services for notebooks" {
            tags "External Dependency"
        }

        openshiftRoute = softwareSystem "OpenShift Route API" "Provides ingress routing with automatic TLS termination" {
            tags "External Dependency" "OpenShift"
        }

        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "Handles user authentication via OpenShift OAuth provider" {
            tags "External Dependency" "OpenShift"
        }

        serviceCA = softwareSystem "OpenShift Service CA Operator" "Auto-provisions TLS certificates for services via annotations" {
            tags "External Dependency" "OpenShift"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Core Kubernetes API for resource management and RBAC" {
            tags "External Dependency"
        }

        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science projects and notebooks" {
            tags "Internal ODH"
        }

        serviceMesh = softwareSystem "Service Mesh (Istio)" "Optional service mesh integration for mTLS and traffic management" {
            tags "Internal ODH" "Optional"
        }

        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection" {
            tags "External Dependency"
        }

        notebookPod = softwareSystem "Notebook Pod" "Running JupyterLab/RStudio instance with optional OAuth proxy sidecar" {
            tags "Workload"
        }

        // User interactions
        user -> odhDashboard "Creates notebooks via web UI"
        user -> notebookPod "Accesses notebook via browser" "HTTPS/443"
        admin -> odhNotebookController "Configures controller settings and annotations"

        // ODH Notebook Controller interactions
        odhDashboard -> k8sAPI "Creates Notebook CRs" "HTTPS/443"
        k8sAPI -> webhook "Calls mutating webhook on Notebook CREATE/UPDATE" "HTTPS/8443 (mTLS)"
        k8sAPI -> reconciler "Notifies of Notebook CR changes" "Watch API"

        reconciler -> k8sAPI "CRUD operations on Routes, Services, Secrets, NetworkPolicies" "HTTPS/443 (SA Token)"
        reconciler -> openshiftRoute "Creates/updates OpenShift Routes for notebook ingress" "via K8s API"
        reconciler -> serviceCA "Triggers TLS cert creation via service annotation" "via K8s API"

        webhook -> notebookPod "Injects OAuth proxy sidecar and volumes into pod spec" "Mutation response"

        // Kubeflow Controller interaction
        k8sAPI -> kubeflowController "Notifies of Notebook CR creation"
        kubeflowController -> k8sAPI "Creates StatefulSets and base Services" "HTTPS/443"
        kubeflowController -> notebookPod "Manages pod lifecycle"

        // Notebook Pod interactions
        notebookPod -> openshiftOAuth "Authenticates users via OAuth 2.0" "HTTPS/443"
        notebookPod -> k8sAPI "Performs SubjectAccessReview for authorization" "HTTPS/443 (SA Token)"
        openshiftRoute -> notebookPod "Routes traffic to notebook" "HTTPS/443 (Reencrypt) or HTTP/80 (Edge)"

        // Optional Service Mesh
        serviceMesh -> notebookPod "Provides mTLS sidecars (mutually exclusive with OAuth)" "mTLS"

        // Monitoring
        prometheus -> reconciler "Scrapes metrics" "HTTP/8080"
        prometheus -> webhook "Scrapes metrics" "HTTP/8080"

        // Dashboard integration
        odhDashboard -> openshiftRoute "Links users to notebook URLs" "HTTPS/443"
    }

    views {
        systemContext odhNotebookController "SystemContext" {
            include *
            autoLayout
            description "System context diagram for ODH Notebook Controller showing interactions with OpenShift platform, Kubeflow, and user workloads"
        }

        container odhNotebookController "Containers" {
            include *
            autoLayout
            description "Container diagram showing internal components of ODH Notebook Controller"
        }

        dynamic odhNotebookController "NotebookCreationFlow" "Notebook creation with OAuth injection" {
            user -> odhDashboard "1. Creates Notebook via Dashboard"
            odhDashboard -> k8sAPI "2. POST Notebook CR"
            k8sAPI -> webhook "3. Mutating webhook call"
            webhook -> k8sAPI "4. Returns mutated spec (OAuth sidecar injected)"
            k8sAPI -> kubeflowController "5. Notebook CR created"
            kubeflowController -> notebookPod "6. Creates StatefulSet with OAuth sidecar"
            k8sAPI -> reconciler "7. Watch event: Notebook created"
            reconciler -> k8sAPI "8. Create Route, Service, ServiceAccount, Secrets, NetworkPolicy"
            reconciler -> serviceCA "9. Trigger TLS cert creation"
            serviceCA -> k8sAPI "10. Create TLS secret"
            reconciler -> k8sAPI "11. Remove culling stop annotation (unlock pod start)"
            autoLayout
            description "Dynamic diagram showing the flow of notebook creation with OAuth proxy injection"
        }

        dynamic odhNotebookController "UserAccessFlow" "User accesses OAuth-enabled notebook" {
            user -> openshiftRoute "1. HTTPS GET /notebook-url (no auth)"
            openshiftRoute -> notebookPod "2. Forward to OAuth proxy (Reencrypt)"
            notebookPod -> user "3. HTTP 302 Redirect to OAuth"
            user -> openshiftOAuth "4. OAuth login flow"
            openshiftOAuth -> user "5. OAuth token"
            user -> openshiftRoute "6. HTTPS GET with OAuth token"
            openshiftRoute -> notebookPod "7. Forward to OAuth proxy"
            notebookPod -> openshiftOAuth "8. Validate token"
            notebookPod -> k8sAPI "9. SubjectAccessReview (authorization)"
            k8sAPI -> notebookPod "10. Authorized: true"
            notebookPod -> user "11. Notebook UI (authenticated)"
            autoLayout
            description "Dynamic diagram showing user authentication and authorization flow for accessing notebooks"
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "External Dependency" {
                background #999999
                color #ffffff
            }
            element "OpenShift" {
                background #ee0000
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Optional" {
                opacity 50
            }
            element "Controller" {
                background #4a90e2
                color #ffffff
            }
            element "Webhook" {
                background #f5a623
                color #ffffff
            }
            element "Workload" {
                background #50c878
                color #ffffff
            }
        }

        theme default
    }
}
