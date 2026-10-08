workspace {
    model {
        user = person "Data Scientist" "Creates and accesses Jupyter Notebook workbenches"
        admin = person "Platform Admin" "Manages RHOAI platform and notebook images"

        kubeflow = softwareSystem "Kubeflow Notebook Controllers" "Manages lifecycle of Jupyter Notebook workbenches on OpenShift" {
            notebookController = container "notebook-controller" "Reconciles Notebook CRs into StatefulSets; manages pod lifecycle and idle culling" "Go / controller-runtime"
            odhController = container "odh-notebook-controller" "OpenShift integration: kube-rbac-proxy injection, Gateway API routing, webhooks, DSPA/MLflow/Feast" "Go / controller-runtime"
            mutatingWebhook = container "Mutating Webhook" "Intercepts Notebook CREATE/UPDATE; injects sidecars, resolves images, sets proxy config" "Go / admission webhook"
            validatingWebhook = container "Validating Webhook" "Validates pod security constraints; prevents unsafe annotation changes" "Go / admission webhook"
            cullingReconciler = container "CullingReconciler" "Detects idle notebooks via kernel probing; scales to zero" "Go / controller-runtime"
        }

        gatewayAPI = softwareSystem "Gateway API (data-science-gateway)" "Envoy-based gateway providing per-notebook ingress routing" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for CRD reconciliation, RBAC, resource management" "External"
        openshift = softwareSystem "OpenShift Platform" "APIServer Config, Image Streams, Routes, OAuth, service-ca-operator" "External"
        dspa = softwareSystem "Data Science Pipelines Operator" "Manages pipeline applications and runtime configuration" "Internal RHOAI"
        mlflow = softwareSystem "MLflow Operator" "Manages MLflow tracking server instances" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor" "External"

        user -> kubeflow "Creates Notebook CR via kubectl/Dashboard"
        user -> gatewayAPI "Accesses notebook UI" "HTTPS/443"
        admin -> openshift "Manages notebook images via ImageStreams"

        notebookController -> k8sAPI "Creates StatefulSets, Services; watches Notebooks" "HTTPS/6443"
        odhController -> k8sAPI "Creates HTTPRoutes, NetworkPolicies, RBAC resources" "HTTPS/6443"
        odhController -> gatewayAPI "Creates per-notebook HTTPRoutes and ReferenceGrants" "HTTPS/6443"
        odhController -> openshift "Reads ImageStreams, APIServer config, Routes" "HTTPS/6443"
        odhController -> dspa "Reads DSPA CRs for pipeline config" "HTTPS/6443"
        odhController -> mlflow "Reads ClusterRole; creates RoleBindings" "HTTPS/6443"
        cullingReconciler -> k8sAPI "Patches Notebook stop annotation" "HTTPS/6443"
        prometheus -> kubeflow "Scrapes metrics" "HTTPS/8443,8080"

        k8sAPI -> mutatingWebhook "Sends admission review" "HTTPS/8443"
        k8sAPI -> validatingWebhook "Sends admission review" "HTTPS/8443"

        gatewayAPI -> kubeflow "Routes to kube-rbac-proxy sidecar" "HTTPS/8443"
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
