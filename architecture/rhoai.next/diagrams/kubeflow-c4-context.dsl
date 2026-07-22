workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, accesses, and manages Jupyter notebook workbenches for ML experimentation"

        kubeflow = softwareSystem "Kubeflow Notebook Controllers" "Manages the lifecycle of Jupyter notebook workbenches on OpenShift, including creation, authentication, networking, idle culling, and ML platform integration" {
            notebookController = container "odh-kf-notebook-controller" "Core notebook lifecycle: creates StatefulSet + Service per Notebook CR, manages status by mirroring Pod conditions, optional idle culling via Jupyter API polling" "Go Operator (controller-runtime)" "odh-kf-notebook-controller-rhel9"
            odhController = container "odh-notebook-controller" "RHOAI platform extensions: kube-rbac-proxy sidecar injection, HTTPRoute creation (Gateway API), NetworkPolicy management, DSPA/MLflow/Feast integration" "Go Operator (controller-runtime) with webhooks" "odh-notebook-controller-rhel9"
            webhookServer = container "Webhook Server" "Mutating (image resolution, auth injection, CA bundles, integration config, update blocking), Validating (MLflow annotation protection), Conversion (v1/v1alpha1 to v1beta1)" "HTTPS :8443"
            kubeRbacProxy = container "kube-rbac-proxy" "Authentication sidecar injected into each notebook pod. Performs SubjectAccessReview to verify user has 'get' access to Notebook CR in namespace" "Go sidecar container" "Injected per-pod"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Core Kubernetes control plane" "External"
        openshiftAPI = softwareSystem "OpenShift API Server" "OpenShift-specific APIs: TLS profiles, ImageStreams, cluster Proxy config" "External"
        gatewayAPI = softwareSystem "data-science-gateway" "Gateway API ingress point for notebook external access (openshift-ingress namespace)" "Internal RHOAI"
        serviceCA = softwareSystem "OpenShift Service CA Operator" "Auto-provisions TLS certificates for services via annotations" "External"
        dspa = softwareSystem "Data Science Pipelines (DSPA)" "Provides S3 credentials and pipeline API endpoint for Elyra notebook integration" "Internal RHOAI"
        mlflow = softwareSystem "MLflow Operator" "Provides mlflow-operator-mlflow-integration ClusterRole for notebook RBAC" "Internal RHOAI"
        feast = softwareSystem "Feast" "Feature store; configuration mounted as ConfigMap into notebook pods" "Internal RHOAI"
        imageStreams = softwareSystem "OpenShift ImageStreams" "Resolve notebook image references to container digests" "External"
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that deploys both controllers as a combined Deployment via kustomize" "Internal RHOAI"

        // User interactions
        dataScientist -> kubeflow "Creates Notebook CR via kubectl/Dashboard, accesses notebook via browser" "HTTPS/443"
        dataScientist -> gatewayAPI "Accesses notebook workbench" "HTTPS/443"

        // Internal interactions
        notebookController -> k8sAPI "Watch/reconcile Notebook CRs, manage StatefulSets, Services, Pods, Events" "HTTPS/6443"
        odhController -> k8sAPI "Watch/reconcile Notebooks, manage HTTPRoutes, ReferenceGrants, NetworkPolicies, RBAC, ConfigMaps, Secrets" "HTTPS/6443"
        kubeRbacProxy -> k8sAPI "SubjectAccessReview, TokenReview for authentication" "HTTPS/6443"

        odhController -> openshiftAPI "Read TLS profiles (APIServer), ImageStreams, cluster Proxy config" "HTTPS/6443"
        odhController -> dspa "Read DSPA CR for S3 credentials and pipeline API endpoint (Elyra)" "HTTPS/6443 via K8s API"
        odhController -> mlflow "Check for mlflow-operator-mlflow-integration ClusterRole; create RoleBinding" "HTTPS/6443 via K8s API"
        odhController -> gatewayAPI "Read Gateway hostname for HTTPRoute parent references and MLflow/Elyra URLs" "HTTPS/6443 via K8s API"

        serviceCA -> kubeRbacProxy "Auto-provisions TLS certificates" "Service annotation"
        serviceCA -> webhookServer "Auto-provisions webhook TLS certificate" "Service annotation"

        rhodsOperator -> kubeflow "Deploys both controllers as combined Deployment" "Kustomize"

        gatewayAPI -> kubeRbacProxy "Routes notebook traffic" "HTTPS/8443"
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
