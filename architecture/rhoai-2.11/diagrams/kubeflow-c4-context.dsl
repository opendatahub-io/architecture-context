workspace {
    model {
        datascientist = person "Data Scientist" "Creates and manages Jupyter notebook workbenches for ML development"

        odhNotebookController = softwareSystem "ODH Notebook Controller" "Extends Kubeflow Notebook Controller with OpenShift-specific ingress and authentication" {
            controller = container "OpenshiftNotebookReconciler" "Watches Notebook CRDs and manages OpenShift resources" "Go Operator" {
                tags "Controller"
            }
            webhook = container "NotebookWebhook" "Mutates Notebook CRs to inject OAuth proxy sidecar" "Go Mutating Webhook" {
                tags "Webhook"
            }
            oauthMgr = container "OAuth Proxy Manager" "Creates and manages OAuth proxy sidecars, services, routes, secrets" "Go Reconciler" {
                tags "Reconciler"
            }
            routeMgr = container "Route Manager" "Creates and manages OpenShift Routes for notebook ingress" "Go Reconciler" {
                tags "Reconciler"
            }
            networkMgr = container "Network Policy Manager" "Creates and manages NetworkPolicies for notebook pods" "Go Reconciler" {
                tags "Reconciler"
            }
            certMgr = container "Certificate Manager" "Manages TLS certificates and trusted CA bundles" "Go Reconciler" {
                tags "Reconciler"
            }
        }

        kubeflowController = softwareSystem "Kubeflow Notebook Controller" "Provides base Notebook CRD and StatefulSet management" "External Dependency"
        openshiftRouter = softwareSystem "OpenShift Ingress Controller" "Routes external traffic to notebook pods" "OpenShift Platform"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "Provides authentication and authorization for notebook access" "OpenShift Platform"
        serviceCA = softwareSystem "OpenShift Service CA Operator" "Provisions and rotates TLS certificates for services" "OpenShift Platform"
        k8sAPI = softwareSystem "Kubernetes API Server" "Manages Kubernetes resources and admission webhooks" "Kubernetes Platform"
        odhDashboard = softwareSystem "ODH Dashboard" "Provides UI for managing and accessing notebooks" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Collects metrics from controller" "Observability"

        # Relationships
        datascientist -> odhDashboard "Creates notebooks via UI"
        datascientist -> k8sAPI "Creates Notebook CRs via kubectl"
        datascientist -> openshiftRouter "Accesses notebooks via browser" "HTTPS/443"

        odhDashboard -> k8sAPI "Creates/manages Notebook CRs" "HTTPS/443"
        odhDashboard -> openshiftRouter "Links to notebook routes"

        k8sAPI -> webhook "Calls mutating webhook on Notebook CREATE/UPDATE" "HTTPS/8443 mTLS"
        webhook -> controller "Triggers reconciliation"

        controller -> k8sAPI "Watches Notebook CRDs, manages resources" "HTTPS/443"
        controller -> oauthMgr "Delegates OAuth resource management"
        controller -> routeMgr "Delegates route creation"
        controller -> networkMgr "Delegates network policy management"
        controller -> certMgr "Delegates certificate management"

        routeMgr -> k8sAPI "Creates OpenShift Routes" "HTTPS/443"
        oauthMgr -> k8sAPI "Creates Services, ServiceAccounts, Secrets" "HTTPS/443"
        networkMgr -> k8sAPI "Creates NetworkPolicies" "HTTPS/443"
        certMgr -> k8sAPI "Manages certificate secrets" "HTTPS/443"

        openshiftRouter -> oauthMgr "Routes traffic to OAuth proxy" "HTTPS/8443 Reencrypt"
        oauthMgr -> openshiftOAuth "Authenticates users" "HTTPS/443"
        openshiftOAuth -> k8sAPI "Performs SubjectAccessReview" "HTTPS/443"

        serviceCA -> webhook "Provisions webhook TLS cert" "Annotation-based"
        serviceCA -> oauthMgr "Provisions OAuth proxy TLS certs" "Annotation-based"

        prometheus -> controller "Scrapes metrics" "HTTP/8080"

        controller -> kubeflowController "Coordinates reconciliation via locks"
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
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Controller" {
                background #4a90e2
                color #ffffff
            }
            element "Webhook" {
                background #f5a623
                color #ffffff
            }
            element "Reconciler" {
                background #7ed321
                color #ffffff
            }
            element "External Dependency" {
                background #999999
                color #ffffff
            }
            element "OpenShift Platform" {
                background #ee0000
                color #ffffff
            }
            element "Kubernetes Platform" {
                background #326ce5
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Observability" {
                background #e8590c
                color #ffffff
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}
