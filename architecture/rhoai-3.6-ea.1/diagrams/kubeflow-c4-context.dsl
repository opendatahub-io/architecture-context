workspace {
    model {
        user = person "Data Scientist" "Creates and manages Kubeflow Notebook workbenches for ML experimentation"

        kubeflow = softwareSystem "Kubeflow Notebook Controllers" "Dual controller system managing Notebook workbench lifecycle with kube-rbac-proxy injection, Gateway API routing, and Elyra pipeline integration" {
            notebookController = container "notebook-controller" "Upstream Kubeflow controller managing Notebook CR lifecycle: StatefulSets, Services, and idle culling" "Go controller-runtime operator"
            odhNotebookController = container "odh-notebook-controller" "Downstream controller extending Notebooks with kube-rbac-proxy sidecar injection, HTTPRoute management, NetworkPolicies, and Elyra secret propagation" "Go controller-runtime operator"
            mutatingWebhook = container "Mutating Webhook" "Intercepts Notebook CREATE/UPDATE to inject kube-rbac-proxy sidecar, proxy env vars, ImageStream resolution, and reconciliation lock" "Admission Webhook /mutate-notebook-v1"
            validatingWebhook = container "Validating Webhook" "Enforces update-time constraints on Notebook resources" "Admission Webhook /validate-notebook-v1"
            conversionWebhook = container "Conversion Webhook" "Handles CRD version migration between v1alpha1, v1beta1, and v1" "Admission Webhook /convert"
        }

        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for ingress routing" "External"
        dataScienceGateway = softwareSystem "data-science-gateway" "Platform-managed Gateway in openshift-ingress namespace" "External"
        dspa = softwareSystem "Data Science Pipelines" "DataSciencePipelinesApplication operator for Elyra runtime integration" "Internal RHOAI"
        kubeAPI = softwareSystem "Kubernetes API Server" "Cluster API server for resource management" "External"
        openshiftAPI = softwareSystem "OpenShift API" "APIServer TLS profiles, Proxy config, ImageStreams, OAuth" "External"

        # User interactions
        user -> kubeflow "Creates Notebook CR via kubectl/dashboard"

        # Internal container relationships
        notebookController -> kubeAPI "Creates StatefulSets, Services; watches Pods; deletes idle pods" "HTTPS/6443"
        odhNotebookController -> kubeAPI "Creates HTTPRoutes, NetworkPolicies, ReferenceGrants, Secrets" "HTTPS/6443"
        odhNotebookController -> dataScienceGateway "Creates HTTPRoutes referencing the gateway" "Gateway API"
        odhNotebookController -> dspa "Reads DataSciencePipelinesApplication CRs for Elyra config" "Kubernetes API"
        odhNotebookController -> openshiftAPI "Reads TLS profiles, Proxy config, ImageStreams" "HTTPS/6443"

        # Webhook flows
        kubeAPI -> mutatingWebhook "Forwards Notebook admission requests" "HTTPS/8443 TLS"
        kubeAPI -> validatingWebhook "Forwards Notebook validation requests" "HTTPS/8443 TLS"
        kubeAPI -> conversionWebhook "Forwards CRD conversion requests" "HTTPS/8443 TLS"

        # External user access
        user -> dataScienceGateway "Accesses notebook workbench UI" "HTTPS/443"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
        }
    }
}
