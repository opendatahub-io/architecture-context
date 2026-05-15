workspace {
    model {
        user = person "Data Scientist" "Creates and manages Jupyter notebook workbenches via Dashboard or kubectl"
        admin = person "Platform Admin" "Configures RHOAI platform, manages namespaces and RBAC"

        kubeflow = softwareSystem "Kubeflow Notebook Controllers" "Dual-controller architecture managing Jupyter notebook workbench lifecycle, networking, authentication, and platform integrations on OpenShift AI" {
            notebookController = container "notebook-controller" "Core Notebook CR lifecycle: creates StatefulSets, Services, optional Istio VirtualServices; manages idle notebook culling via Jupyter API polling" "Go Operator (controller-runtime)"
            odhNotebookController = container "odh-notebook-controller" "RHOAI extensions: Gateway API HTTPRoutes, kube-rbac-proxy sidecar injection, NetworkPolicies, admission webhooks, DSPA/MLflow/Feast integrations, certificate trust chain management" "Go Operator (controller-runtime) + Admission Webhooks"
            mutatingWebhook = container "Mutating Webhook" "Intercepts Notebook CREATE/UPDATE to inject auth sidecars, CA bundles, proxy env, pipeline config, feature store config, MLflow tracking, and ImageStream resolution" "Go Webhook Server (443/TCP HTTPS)"
            validatingWebhook = container "Validating Webhook" "Prevents removal of MLflow annotation while notebook is running" "Go Webhook Server (443/TCP HTTPS)"
        }

        kubernetes = softwareSystem "Kubernetes / OpenShift" "Container orchestration platform providing API server, RBAC, and resource management" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API providing HTTPRoute-based ingress for notebook access" "External"
        gateway = softwareSystem "data-science-gateway" "Central ingress gateway in openshift-ingress namespace serving all notebook traffic" "External"

        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science workbenches and projects" "Internal RHOAI"
        dspa = softwareSystem "Data Science Pipelines (DSPA)" "Pipeline orchestration platform providing Elyra pipeline configuration" "Internal RHOAI"
        mlflow = softwareSystem "MLflow Operator" "ML experiment tracking and model registry" "Internal RHOAI"
        feast = softwareSystem "Feast" "Feature store providing feature retrieval configuration" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator managing Gateway CR and platform webhooks" "Internal RHOAI"
        imageStreams = softwareSystem "OpenShift ImageStreams" "Container image management and tag resolution" "External"
        certManager = softwareSystem "OpenShift Service Serving Cert / CA" "Automatic TLS certificate provisioning and CA trust management" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Authentication sidecar providing TokenReview/SubjectAccessReview-based access control" "External"

        # User interactions
        user -> dashboard "Creates notebook workbenches via" "HTTPS"
        user -> gateway "Accesses notebooks via" "HTTPS/443 Bearer Token (OIDC)"
        user -> kubernetes "Creates Notebook CRs via kubectl" "HTTPS/6443"
        admin -> kubernetes "Manages platform configuration" "HTTPS/6443"

        # Dashboard integration
        dashboard -> kubernetes "Sets image selection annotation on Notebook CRs" "HTTPS/6443"

        # Controller interactions with Kubernetes
        notebookController -> kubernetes "Watches Notebook CRs, manages StatefulSets and Services" "HTTPS/6443 SA token"
        odhNotebookController -> kubernetes "Watches Notebook/Gateway/DSPA CRs, manages HTTPRoutes, NetworkPolicies, RBAC" "HTTPS/6443 SA token"

        # Webhook interactions
        kubernetes -> mutatingWebhook "Admission webhook calls on Notebook CREATE/UPDATE" "HTTPS/443 serving cert"
        kubernetes -> validatingWebhook "Admission webhook calls on Notebook UPDATE" "HTTPS/443 serving cert"
        mutatingWebhook -> imageStreams "Resolves container images from ImageStream tags" "HTTPS/6443 SA token"

        # Internal component relationships
        odhNotebookController -> mutatingWebhook "Registers" ""
        odhNotebookController -> validatingWebhook "Registers" ""

        # Culling
        notebookController -> kubernetes "Polls notebook Jupyter API for idle detection" "HTTP/8888"

        # Platform integrations
        odhNotebookController -> dspa "Reads DSPA CR for pipeline endpoints and credentials" "CRD Watch HTTPS/6443"
        odhNotebookController -> mlflow "Creates RoleBindings granting notebook SAs MLflow access" "ClusterRole reference"
        odhNotebookController -> feast "Mounts Feast config into notebook pods" "ConfigMap"
        odhNotebookController -> rhodsOperator "Reads Gateway CR for hostname resolution" "CRD Watch HTTPS/6443"

        # External services
        odhNotebookController -> certManager "Provisions TLS certs for webhook and kube-rbac-proxy" "Annotation-driven"
        kubeflow -> kubeRBACProxy "Injects as sidecar for per-notebook auth" "Sidecar injection"

        # Gateway flow
        gateway -> kubeRBACProxy "Routes notebook traffic to auth sidecar" "HTTPS/8443"

        # Monitoring
        prometheus -> kubeflow "Scrapes metrics (notebook_running, notebook_create_total, notebook_culling_total)" "HTTP/8080"
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
                background #4a90e2
                color #ffffff
                shape person
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
