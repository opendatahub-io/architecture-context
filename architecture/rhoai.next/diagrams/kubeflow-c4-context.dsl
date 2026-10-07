workspace {
    model {
        user = person "Data Scientist" "Creates and manages Jupyter notebook workbenches via Dashboard or kubectl"

        kubeflow = softwareSystem "Kubeflow Notebook Controllers" "Manages lifecycle of Jupyter Notebook workbenches on OpenShift with auth injection, network isolation, and Gateway API routing" {
            kfController = container "kf-notebook-controller" "Upstream Kubeflow controller that reconciles Notebook CRs into StatefulSets and Services; optional idle-culling" "Go controller-runtime"
            odhController = container "odh-notebook-controller" "Downstream controller adding OpenShift auth injection, NetworkPolicy, Gateway API routing, DSPA/MLflow integration" "Go controller-runtime"
            mutatingWebhook = container "NotebookWebhook" "Mutating admission webhook: injects kube-rbac-proxy sidecar, resolves ImageStream refs, sets proxy env vars, reconciliation lock" "Go admission webhook"
            validatingWebhook = container "NotebookValidatingWebhook" "Validating admission webhook: enforces pod security constraints, guards MLflow annotation removal" "Go admission webhook"
        }

        gatewayAPI = softwareSystem "Gateway API" "Central gateway for external notebook access via HTTPRoute/ReferenceGrant" "External"
        dspa = softwareSystem "Data Science Pipelines Operator" "Manages DataSciencePipelinesApplication CRs; provides pipeline connection secrets" "Internal RHOAI"
        imageStreams = softwareSystem "OpenShift Image Streams" "Resolves image references to container digests" "External"
        osOAuth = softwareSystem "OpenShift OAuth" "Cluster OAuth server for legacy notebook authentication" "External"
        osConfig = softwareSystem "OpenShift Config" "Cluster TLS security profile and proxy configuration" "External"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Per-notebook auth sidecar performing TokenReview" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Central API server for all resource operations" "External"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing notebook workbenches" "Internal RHOAI"

        user -> dashboard "Creates notebooks via web UI"
        user -> kubeflow "Creates Notebook CRs via kubectl"
        dashboard -> kubeflow "Manages notebook lifecycle"

        kubeflow -> gatewayAPI "Creates HTTPRoutes and ReferenceGrants for external notebook access" "HTTPS/6443"
        kubeflow -> dspa "Watches DSPA CRs; provisions pipeline secrets" "HTTPS/6443"
        kubeflow -> imageStreams "Resolves ImageStream tags to image digests" "HTTPS/6443"
        kubeflow -> osOAuth "Manages OAuthClient resources (legacy)" "HTTPS/6443"
        kubeflow -> osConfig "Reads TLS profile and proxy config; watches for changes" "HTTPS/6443"
        kubeflow -> k8sAPI "All resource CRUD: Notebooks, StatefulSets, Services, NetworkPolicies, RBAC, Secrets" "HTTPS/6443"

        odhController -> kfController "Coordinates via reconciliation lock annotation"
        mutatingWebhook -> kubeRBACProxy "Injects as sidecar into notebook pods"

        prometheus -> kubeflow "Scrapes metrics" "HTTPS/8443"
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
                color #000000
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
