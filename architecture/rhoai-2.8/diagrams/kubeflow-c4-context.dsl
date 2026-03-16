workspace {
    model {
        user = person "Data Scientist" "Creates and manages Jupyter notebooks for ML/AI development"

        odhNotebookController = softwareSystem "ODH Notebook Controller" "Extends Kubeflow Notebook Controller with OpenShift-specific features: Routes, OAuth proxy, network policies, and TLS certificate management" {
            controller = container "OpenshiftNotebookReconciler" "Reconciles Notebook CRs and creates OpenShift resources" "Go Controller"
            webhook = container "NotebookWebhook" "Mutating webhook that injects OAuth proxy sidecar" "Go Mutating Webhook"
            oauthProxy = container "OAuth Proxy Sidecar" "Provides authentication and authorization for notebook access" "OpenShift OAuth Proxy" "Injected"
        }

        kubeflowNotebookController = softwareSystem "Kubeflow Notebook Controller" "Base Notebook CR controller; creates StatefulSet for notebook pods" "External"
        openshiftRouteAPI = softwareSystem "OpenShift Route API" "Manages ingress routing with TLS termination" "External"
        openshiftConfigAPI = softwareSystem "OpenShift Config API" "Provides cluster-wide proxy configuration" "External"
        openshiftOAuthServer = softwareSystem "OpenShift OAuth Server" "Authenticates users via OpenShift identity provider" "External"
        serviceCAOperator = softwareSystem "OpenShift Service CA Operator" "Auto-provisions TLS certificates for services" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Core API for watching and managing resources" "External"

        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for creating and managing data science resources" "Internal ODH"
        odhOperator = softwareSystem "ODH Operator" "Deploys and manages ODH components" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Collects metrics from ODH components" "Internal ODH"

        containerRegistry = softwareSystem "Container Registries" "Stores notebook and OAuth proxy container images" "External"

        %% User interactions
        user -> odhDashboard "Creates notebooks via web UI"
        user -> k8sAPI "Creates Notebook CRs via kubectl/oc"
        user -> odhNotebookController "Accesses notebooks via OpenShift Routes (HTTPS)"

        %% ODH Dashboard interaction
        odhDashboard -> k8sAPI "Creates Notebook CRs"

        %% ODH Operator deployment
        odhOperator -> odhNotebookController "Deploys and manages controller"

        %% Controller internal interactions
        controller -> webhook "Runs in same deployment"
        oauthProxy -> controller "Created and configured by controller"

        %% External dependencies
        odhNotebookController -> k8sAPI "Watches Notebook CRs, creates/manages resources (Routes, Services, Secrets, NetworkPolicies, ConfigMaps)" "HTTPS/6443 (TLS 1.3, SA token)"
        odhNotebookController -> openshiftRouteAPI "Creates Routes for external access" "HTTPS/6443 (via K8s API)"
        odhNotebookController -> openshiftConfigAPI "Reads cluster proxy configuration" "HTTPS/6443 (via K8s API)"
        odhNotebookController -> serviceCAOperator "Requests TLS certificate provisioning via annotations" "Annotation-based"
        odhNotebookController -> containerRegistry "Pulls OAuth proxy and notebook images" "HTTPS/443 (TLS 1.2+)"

        %% OAuth proxy dependencies
        oauthProxy -> openshiftOAuthServer "Authenticates users via OAuth 2.0" "HTTPS/6443 (TLS 1.3)"
        oauthProxy -> k8sAPI "Performs SubjectAccessReview for authorization" "HTTPS/6443 (TLS 1.3, user token)"

        %% Kubeflow controller interaction
        kubeflowNotebookController -> k8sAPI "Watches same Notebook CRs, creates StatefulSets"
        odhNotebookController -> kubeflowNotebookController "Complements by adding OpenShift integrations"

        %% Monitoring
        prometheus -> odhNotebookController "Scrapes /metrics endpoint" "HTTP/8080"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Injected" {
                background #f5a623
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #6c8ebf
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
