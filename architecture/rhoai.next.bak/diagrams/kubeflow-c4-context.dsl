workspace {
    model {
        user = person "Data Scientist" "Creates and manages Jupyter notebook workbenches via Dashboard or kubectl"
        admin = person "Platform Admin" "Manages RHOAI platform configuration and RBAC"

        kubeflow = softwareSystem "Kubeflow Notebook Controller" "Kubernetes operator that manages the lifecycle, networking, authentication, and integrations for Jupyter notebook workbenches on OpenShift AI" {
            kfController = container "kf-notebook-controller" "Core Notebook lifecycle: StatefulSet, Service, VirtualService creation; idle notebook culling via Jupyter API polling" "Go Operator (controller-runtime)" "operator"
            odhController = container "odh-notebook-controller" "OpenShift extensions: Gateway API ingress (HTTPRoute), kube-rbac-proxy sidecar injection, NetworkPolicy, CA cert management, DSPA/MLflow/Feast integrations, mutating/validating webhooks" "Go Operator (controller-runtime)" "operator"
            mutatingWebhook = container "Mutating Webhook" "Intercepts Notebook CR create/update: injects sidecars, certs, config, resolves ImageStreams, blocks risky updates" "Go Webhook Server" "webhook"
            validatingWebhook = container "Validating Webhook" "Prevents removal of MLflow annotation on running notebooks" "Go Webhook Server" "webhook"
        }

        notebookPod = softwareSystem "Notebook Pod" "User's Jupyter notebook workbench running as a StatefulSet pod with kube-rbac-proxy sidecar" "managed"

        # External dependencies
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for all CRUD operations" "External"
        gateway = softwareSystem "data-science-gateway" "Gateway API resource for external ingress routing" "Internal Platform"
        dspa = softwareSystem "Data Science Pipelines" "Data Science Pipelines Application for ML pipeline execution" "Internal Platform"
        mlflow = softwareSystem "MLflow Operator" "ML experiment tracking and model registry" "Internal Platform"
        feast = softwareSystem "Feast Operator" "Feature store for ML features" "Internal Platform"
        imageStreams = softwareSystem "OpenShift ImageStreams" "Container image metadata and resolution" "External"
        serviceCA = softwareSystem "OpenShift Service CA" "Automatic TLS certificate generation for services" "External"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science workbenches" "Internal Platform"
        platformOperator = softwareSystem "rhods-operator" "Platform operator that deploys this component via kustomize manifests" "Internal Platform"

        # Relationships - User
        user -> dashboard "Creates notebooks via" "HTTPS/443"
        user -> notebookPod "Accesses Jupyter via" "HTTPS/443 (Gateway → kube-rbac-proxy)"
        admin -> k8sAPI "Manages RBAC and configuration" "HTTPS/6443"

        # Relationships - Dashboard
        dashboard -> k8sAPI "Creates Notebook CRs" "HTTPS/6443"
        dashboard -> kubeflow "Reads update-pending annotation" "Annotation protocol"

        # Relationships - Controller to K8s API
        kfController -> k8sAPI "CRUD StatefulSets, Services, Pods, Events, Notebooks" "HTTPS/6443, SA token"
        odhController -> k8sAPI "CRUD HTTPRoutes, NetworkPolicies, Secrets, ConfigMaps, RBAC" "HTTPS/6443, SA token"

        # Relationships - Webhook
        k8sAPI -> mutatingWebhook "Calls on Notebook create/update" "HTTPS/8443, mTLS"
        k8sAPI -> validatingWebhook "Calls on Notebook update" "HTTPS/8443, mTLS"

        # Relationships - Controller to external systems
        odhController -> gateway "Reads Gateway hostname for HTTPRoute parent ref" "HTTPS/6443, CRD Watch"
        odhController -> dspa "Reads DSPA status for pipeline API endpoint and S3 config" "HTTPS/6443, CRD Watch"
        odhController -> mlflow "Binds MLflow ClusterRole to notebook SA" "HTTPS/6443, ClusterRole lookup"
        odhController -> imageStreams "Resolves ImageStream refs to container images" "HTTPS/6443, CRD Watch"
        kfController -> notebookPod "Polls Jupyter API for idle detection" "HTTP/8888"

        # Relationships - Infrastructure
        serviceCA -> notebookPod "Auto-generates TLS certs for kube-rbac-proxy" "Annotation-triggered"
        platformOperator -> kubeflow "Deploys via kustomize manifests" "get_all_manifests.sh"

        # Relationships - Notebook access
        gateway -> notebookPod "Routes /notebook/{ns}/{name} traffic" "HTTPS/8443, TLS"
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
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "managed" {
                background #4a90e2
                color #ffffff
            }
            element "operator" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "webhook" {
                background #f5a623
                color #ffffff
                shape Hexagon
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
