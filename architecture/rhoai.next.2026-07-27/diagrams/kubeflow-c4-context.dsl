workspace {
    model {
        user = person "Data Scientist" "Creates and manages Jupyter notebook workbenches"

        kubeflow = softwareSystem "Kubeflow Notebook Controller" "Manages lifecycle of Jupyter notebook workbenches on Kubernetes" {
            controller = container "notebook-controller-deployment" "Reconciles Notebook CRs, manages StatefulSets, Services, and OpenShift resources" "Go Operator (controller-runtime 0.23.3)"
            webhookServer = container "Admission Webhooks" "Validates, mutates, and converts Notebook CRs" "Go Webhook Server (HTTPS TLS)"
            reconcileLib = container "Common Reconcile Library" "Shared create-or-update patterns for Deployments, Services, StatefulSets, VirtualServices" "Go Library"
        }

        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for HTTP routing" "External"
        openshiftAPI = softwareSystem "OpenShift API" "OpenShift-specific APIs (Routes, ImageStreams, OAuthClients)" "External"
        dspOperator = softwareSystem "Data Science Pipelines Operator" "Manages data science pipeline applications" "Internal ODH"
        istio = softwareSystem "Istio" "Service mesh for traffic management (optional via ConfigMap)" "External"

        user -> kubeflow "Creates Notebook CR via kubectl/dashboard"
        kubeflow -> k8sAPI "Manages StatefulSets, Services, NetworkPolicies, RBAC" "HTTPS/6443 TLS 1.2+"
        kubeflow -> gatewayAPI "Creates/manages HTTPRoutes and ReferenceGrants" "HTTPS TLS 1.2+"
        kubeflow -> openshiftAPI "Reads Routes, ImageStreams; manages OAuthClients" "HTTPS/6443 TLS 1.2+"
        kubeflow -> dspOperator "Reads DataSciencePipelinesApplications" "Go library import"
        kubeflow -> istio "Creates VirtualServices (when USE_ISTIO=true)" "Kubernetes API TLS"

        controller -> reconcileLib "Uses create-or-update patterns" "Go function calls"
        controller -> webhookServer "Registers admission webhooks" "Internal"
        k8sAPI -> webhookServer "Sends admission requests" "HTTPS/443 TLS"
    }

    views {
        systemContext kubeflow "SystemContext" {
            include *
            autoLayout
        }

        container kubeflow "Containers" {
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
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
