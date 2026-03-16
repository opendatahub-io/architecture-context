workspace {
    model {
        user = person "Data Scientist" "Creates and accesses Jupyter notebook workloads on OpenShift"

        kubeflow = softwareSystem "ODH Notebook Controller" "Extends Kubeflow Notebooks with OpenShift-specific capabilities including OAuth authentication, route-based ingress, and network isolation" {
            controller = container "OpenshiftNotebookReconciler" "Reconciles Notebook CRs and creates supporting OpenShift resources" "Go Operator" {
                reconciler = component "Notebook Reconciler" "Watches Notebook CRs and creates Routes, Services, Secrets, NetworkPolicies" "Go Controller"
                caManager = component "CA Bundle Manager" "Merges trusted CA certificates from cluster and ODH configs" "Go Controller"
            }
            webhook = container "NotebookWebhook" "Mutating webhook that injects OAuth proxy and CA bundles" "Go MutatingWebhook" {
                mutator = component "Notebook Mutator" "Injects OAuth proxy sidecar and environment variables" "Go Webhook Handler"
                imageResolver = component "ImageStream Resolver" "Resolves ImageStream references to container image digests" "Go Webhook Handler"
            }
            manager = container "Manager Deployment" "Hosts the controller and webhook server" "Kubernetes Deployment"
        }

        kubernetes = softwareSystem "Kubernetes API Server" "Container orchestration platform" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller for external access" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "User authentication and authorization" "External"
        openshiftServiceCA = softwareSystem "OpenShift Service CA" "Automatic TLS certificate provisioning" "External"
        imageStreamAPI = softwareSystem "OpenShift ImageStream API" "Container image management and resolution" "External"

        kubeflowController = softwareSystem "Kubeflow Notebook Controller" "Creates StatefulSets for notebook pods" "Internal ODH"
        odhOperator = softwareSystem "ODH Operator" "Provides trusted CA bundle ConfigMaps" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal ODH"

        containerRegistry = softwareSystem "Container Registries" "Stores OAuth proxy and notebook container images" "External"

        // User interactions
        user -> kubeflow "Creates and accesses Notebook CRs via kubectl/UI"
        user -> openshiftRouter "Accesses notebook UI via HTTPS"

        // Controller interactions with Kubernetes API
        kubeflow -> kubernetes "Watches Notebook CRs, creates/updates Routes, Services, Secrets, ServiceAccounts, NetworkPolicies, ConfigMaps" "HTTPS/6443 TLS1.2+"
        kubernetes -> kubeflow "Sends Notebook CR watch events and webhook admission requests" "HTTPS/8443 mTLS"

        // External OpenShift dependencies
        kubeflow -> openshiftRouter "Creates Routes for external notebook access" "Kubernetes API"
        kubeflow -> imageStreamAPI "Resolves ImageStream references to container image digests" "HTTPS/6443 TLS1.2+"
        kubeflow -> openshiftServiceCA "Requests TLS certificates via service annotations" "Kubernetes API"

        // OAuth flow
        openshiftRouter -> kubeflow "Routes external traffic to notebook OAuth proxy" "HTTPS/8443 TLS1.2+ Reencrypt"
        kubeflow -> openshiftOAuth "OAuth proxy authenticates users" "OAuth 2.0 / HTTPS/443"
        kubeflow -> kubernetes "OAuth proxy performs SubjectAccessReview for authorization" "HTTPS/6443 TLS1.2+"

        // Internal ODH dependencies
        kubeflow -> kubeflowController "Extends functionality of Notebook CRs (shared CRD)" "Watches same Notebook resources"
        kubeflow -> odhOperator "Watches odh-trusted-ca-bundle ConfigMap" "Kubernetes API"
        kubeflow -> prometheus "Exposes metrics on /metrics endpoint" "HTTP/8080"

        // External services
        kubeflow -> containerRegistry "Pulls OAuth proxy and notebook container images" "HTTPS/443 TLS1.2+"
    }

    views {
        systemContext kubeflow "SystemContext" {
            include *
            autoLayout lr
        }

        container kubeflow "Containers" {
            include *
            autoLayout tb
        }

        component controller "ControllerComponents" {
            include *
            autoLayout tb
        }

        component webhook "WebhookComponents" {
            include *
            autoLayout tb
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}
