workspace {
    model {
        user = person "Data Scientist" "Creates and manages Jupyter notebooks for ML/data science workloads"

        odhNotebookController = softwareSystem "ODH Notebook Controller" "Extends Kubeflow notebooks with OpenShift-specific ingress (Routes) and OAuth authentication" {
            controller = container "OpenshiftNotebookReconciler" "Reconciles Notebook CRs and creates Routes, Services, Secrets, NetworkPolicies" "Go Controller" "Controller"
            webhook = container "NotebookWebhook" "Mutating webhook that injects OAuth proxy sidecar and cluster-wide proxy config" "Go Webhook" "Controller"
            webhookServer = container "Webhook Server" "Serves mutating webhook endpoint with TLS" "HTTPS Server (port 8443)" "WebServer"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics" "HTTP Server (port 8080)" "WebServer"
            healthProbes = container "Health Probes" "Provides liveness and readiness endpoints" "HTTP Server (port 8081)" "WebServer"
        }

        notebookPod = softwareSystem "Notebook Pod" "Jupyter notebook instance with OAuth proxy sidecar" "NotebookPod"

        kubeflowController = softwareSystem "Kubeflow Notebook Controller" "Upstream controller that creates StatefulSets for notebooks" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller for external access" "External"
        oauthServer = softwareSystem "OpenShift OAuth Server" "Provides authentication for notebook access" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane API" "External"
        serviceCA = softwareSystem "Service CA Operator" "Automatic TLS certificate provisioning for services" "External"
        clusterProxy = softwareSystem "Cluster-wide Proxy" "Optional proxy for notebook egress traffic" "External"

        # User interactions
        user -> odhNotebookController "Creates Notebook CRs via kubectl/Dashboard"
        user -> notebookPod "Accesses notebooks via browser" "HTTPS/443"

        # Controller interactions
        controller -> k8sAPI "Watches Notebook CRs, creates Routes/Services/Secrets/NetworkPolicies" "HTTPS/6443"
        webhook -> k8sAPI "Reads cluster-wide Proxy configuration" "HTTPS/6443"
        webhookServer -> k8sAPI "Receives mutating webhook requests" "HTTPS/443 (mTLS)"

        # External dependencies
        odhNotebookController -> kubeflowController "Watches Notebook CRs created by upstream controller" "Kubernetes Watch API"
        odhNotebookController -> openshiftRouter "Creates Routes for external notebook access" "OpenShift Route API"
        odhNotebookController -> serviceCA "Triggers TLS certificate provisioning via annotations" "Service Annotations"

        # Notebook access flow
        openshiftRouter -> notebookPod "Routes external HTTPS traffic to notebooks" "HTTPS/443"
        notebookPod -> oauthServer "Authenticates users via OAuth proxy" "HTTPS/443"
        notebookPod -> k8sAPI "Authorizes users via SubjectAccessReview" "HTTPS/6443"

        # Optional cluster proxy
        webhook -> clusterProxy "Injects proxy config into notebook pods" "ConfigMap injection"
        notebookPod -> clusterProxy "Proxies egress traffic (if configured)" "HTTP/HTTPS"
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
            element "Controller" {
                background #4a90e2
                color #ffffff
            }
            element "WebServer" {
                background #7ed321
                color #000000
            }
            element "NotebookPod" {
                background #f5a623
                color #000000
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}
