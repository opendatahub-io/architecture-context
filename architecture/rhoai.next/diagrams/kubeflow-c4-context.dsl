workspace {
    model {
        user = person "Data Scientist" "Creates and manages Jupyter notebook workbenches via RHOAI Dashboard or kubectl"

        kubeflow = softwareSystem "Kubeflow Notebook Controllers" "Dual-controller architecture managing Jupyter notebook lifecycle, auth, networking, and platform integrations on RHOAI" {
            notebookController = container "notebook-controller" "Core notebook lifecycle: StatefulSet, Service, VirtualService creation; pod status mirroring; idle notebook culling via Jupyter kernel/terminal API polling" "Go Operator (controller-runtime)"
            odhNotebookController = container "odh-notebook-controller" "RHOAI extensions: kube-rbac-proxy sidecar injection, HTTPRoute/ReferenceGrant management, NetworkPolicy creation, DSPA/MLflow/Feast integrations, mutating/validating webhooks" "Go Operator (controller-runtime)"
            commonLib = container "common" "Shared reconciliation helpers for Deployment, Service, StatefulSet, VirtualService resources" "Go Library"
            mutatingWebhook = container "Mutating Webhook" "Intercepts Notebook CR creation to inject kube-rbac-proxy sidecar, DSPA secrets, MLflow env vars, Feast config, ImageStream resolution" "HTTPS/8443"
            validatingWebhook = container "Validating Webhook" "Prevents removal of MLflow annotations on running notebooks" "HTTPS/8443"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Core cluster API for all resource CRUD operations" "External" {
            tags "External"
        }

        gatewayAPI = softwareSystem "Gateway API (data-science-gateway)" "Gateway API Gateway for external notebook access via HTTPRoutes" "External" {
            tags "External"
        }

        openshiftServiceCA = softwareSystem "OpenShift Service CA" "Provides TLS certificates for webhook and kube-rbac-proxy services" "External" {
            tags "External"
        }

        openshiftImageStreams = softwareSystem "OpenShift ImageStreams" "Resolves notebook container images from ImageStream tags" "External" {
            tags "External"
        }

        dspa = softwareSystem "Data Science Pipelines Operator" "Provides DSPA CRD for pipeline configuration and S3 credentials" "Internal RHOAI" {
            tags "Internal"
        }

        mlflow = softwareSystem "MLflow Operator" "Provides MLflow tracking integration via ClusterRole binding" "Internal RHOAI" {
            tags "Internal"
        }

        feast = softwareSystem "Feast" "Feature store integration via ConfigMap mounting" "Internal RHOAI" {
            tags "Internal"
        }

        rhodsOperator = softwareSystem "rhods-operator / Gateway Controller" "Manages Gateway CR providing hostname for HTTPRoute parentRef" "Internal RHOAI" {
            tags "Internal"
        }

        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Per-notebook auth sidecar: TokenReview + SubjectAccessReview enforcement" "Sidecar" {
            tags "Sidecar"
        }

        # Relationships
        user -> kubeflow "Creates Notebook CR via kubectl/Dashboard"
        user -> gatewayAPI "Accesses notebook UI" "HTTPS/443"

        kubeflow -> kubernetesAPI "CRUD on StatefulSets, Services, HTTPRoutes, NetworkPolicies, Secrets" "HTTPS/6443"
        kubeflow -> gatewayAPI "Reads Gateway CR hostname; creates HTTPRoutes" "HTTPS/6443 (via K8s API)"
        kubeflow -> openshiftServiceCA "Receives TLS certificates" "Auto-injection"
        kubeflow -> openshiftImageStreams "Resolves notebook images" "HTTPS/6443 (via K8s API)"
        kubeflow -> dspa "Reads DSPA CR for S3 config; creates pipeline secrets" "HTTPS/6443 (via K8s API)"
        kubeflow -> mlflow "Creates ClusterRole bindings per notebook" "HTTPS/6443 (via K8s API)"
        kubeflow -> feast "Mounts Feast ConfigMap per notebook" "K8s ConfigMap"
        kubeflow -> rhodsOperator "Reads Gateway CR hostname" "HTTPS/6443 (via K8s API)"
        kubeflow -> kubeRBACProxy "Injects as sidecar into notebook pods" "Webhook mutation"

        gatewayAPI -> kubeRBACProxy "Routes notebook traffic" "HTTPS/8443"
        kubeRBACProxy -> kubernetesAPI "TokenReview + SubjectAccessReview" "HTTPS/6443"

        notebookController -> commonLib "Uses reconciliation helpers"
        odhNotebookController -> commonLib "Uses reconciliation helpers"
        odhNotebookController -> mutatingWebhook "Serves"
        odhNotebookController -> validatingWebhook "Serves"

        kubernetesAPI -> mutatingWebhook "Calls on Notebook CR create/update" "HTTPS/8443"
        kubernetesAPI -> validatingWebhook "Calls on Notebook CR create/update" "HTTPS/8443"
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
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Sidecar" {
                background #d0021b
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
