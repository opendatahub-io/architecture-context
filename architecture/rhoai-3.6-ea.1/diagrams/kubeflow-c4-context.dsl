workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Jupyter notebook workbenches"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform configuration"

        kubeflow = softwareSystem "Kubeflow Notebooks" "Manages the lifecycle of Jupyter notebook workbenches on OpenShift with authentication, routing, and pipeline integration" {
            notebookController = container "notebook-controller" "Reconciles Notebook CRs into StatefulSets, Services, and Events; handles pod lifecycle and idle culling" "Go controller-runtime Operator"
            odhNotebookController = container "odh-notebook-controller" "Extends upstream with kube-rbac-proxy sidecar injection, Gateway API routing, NetworkPolicy, and DSPA pipeline integration" "Go controller-runtime Operator"
            mutatingWebhook = container "Mutating Webhook" "Injects kube-rbac-proxy sidecar and stop annotation lock into Notebook pods" "Admission Webhook"
            validatingWebhook = container "Validating Webhook" "Validates Notebook updates" "Admission Webhook"
            conversionWebhook = container "Conversion Webhook" "Converts between Notebook API versions (v1, v1alpha1, v1beta1)" "Admission Webhook"
        }

        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource operations" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for ingress routing (data-science-gateway)" "External"
        openshiftAPI = softwareSystem "OpenShift APIServer" "Platform TLS security profile and proxy configuration" "External"
        dspa = softwareSystem "Data Science Pipelines Operator" "Manages DataSciencePipelinesApplication CRs for pipeline workflows" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing RHOAI resources" "Internal RHOAI"
        imageStreams = softwareSystem "OpenShift Image Streams" "Container image metadata and tagging" "External"

        # Relationships
        dataScientist -> dashboard "Creates Notebook workbenches via"
        dataScientist -> kubeflow "Creates Notebook CRs via kubectl"
        platformAdmin -> openshiftAPI "Configures TLS security profiles"

        dashboard -> k8sAPI "Creates Notebook CRs" "HTTPS/6443"

        kubeflow -> k8sAPI "Watches and manages Kubernetes resources" "HTTPS/6443 TLS 1.2+"
        kubeflow -> gatewayAPI "Creates HTTPRoutes and ReferenceGrants for notebook ingress" "HTTPS/6443"
        kubeflow -> openshiftAPI "Reads TLS security profile at startup" "HTTPS/6443"
        kubeflow -> dspa "Reads DSPA CRs to provision Elyra pipeline runtime secrets" "HTTPS/6443"
        kubeflow -> imageStreams "Reads image stream metadata" "HTTPS/6443"

        k8sAPI -> mutatingWebhook "Sends admission reviews on Notebook CREATE/UPDATE" "HTTPS/8443"
        k8sAPI -> validatingWebhook "Sends admission reviews on Notebook UPDATE" "HTTPS/8443"
        k8sAPI -> conversionWebhook "Sends conversion requests" "HTTPS"

        odhNotebookController -> mutatingWebhook "Serves"
        odhNotebookController -> validatingWebhook "Serves"
        odhNotebookController -> conversionWebhook "Serves"
        notebookController -> k8sAPI "Creates StatefulSets, Services, Events" "HTTPS/6443"
        odhNotebookController -> k8sAPI "Creates NetworkPolicies, RoleBindings, Secrets" "HTTPS/6443"
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
                shape person
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
