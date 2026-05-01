workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Jupyter notebook workbenches"
        platformAdmin = person "Platform Admin" "Configures RHOAI platform and notebook settings"

        kubeflow = softwareSystem "Kubeflow Notebook Controllers" "Manages the lifecycle of Jupyter Notebook workbenches on OpenShift, providing creation, routing, authentication, idle detection, and platform integration" {
            kfController = container "KF Notebook Controller" "Core notebook lifecycle: StatefulSet, Service management, idle culling" "Go Operator (controller-runtime)"
            odhController = container "ODH Notebook Controller" "RHOAI extensions: HTTPRoute routing, kube-rbac-proxy auth, NetworkPolicy, webhook mutations, MLflow/Elyra/Feast integration" "Go Operator (controller-runtime)"
            mutatingWebhook = container "Mutating Webhook" "Injects configuration at notebook creation: image resolution, CA bundles, proxy settings, auth sidecars, MLflow env vars" "Admission Webhook (8443/TCP HTTPS)"
            validatingWebhook = container "Validating Webhook" "Prevents unsafe state transitions (e.g., MLflow annotation removal on running notebooks)" "Admission Webhook (8443/TCP HTTPS)"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Core API server for all cluster operations" "External"
        gatewayAPI = softwareSystem "data-science-gateway" "Central Gateway API ingress gateway (Envoy) in openshift-ingress namespace" "External"
        openshiftImageRegistry = softwareSystem "OpenShift Image Registry" "ImageStream tag to digest resolution for notebook images" "External"
        openshiftServiceCA = softwareSystem "OpenShift Service CA" "Auto-provisions TLS certificates for services and webhooks" "External"
        dataSciencePipelines = softwareSystem "Data Science Pipelines" "Pipeline execution and Elyra runtime configuration" "Internal RHOAI"
        mlflowOperator = softwareSystem "MLflow Operator" "Provides MLflow integration ClusterRole for notebook ServiceAccounts" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing RHOAI workbenches" "Internal RHOAI"
        istio = softwareSystem "Istio" "Service mesh (optional, Kubeflow overlay only)" "External"
        feastIntegration = softwareSystem "Feast" "Feature store integration via label-driven ConfigMap mount" "Internal RHOAI"

        # User interactions
        dataScientist -> odhDashboard "Creates notebook workbenches via" "HTTPS/443"
        dataScientist -> gatewayAPI "Accesses notebooks via" "HTTPS/443 TLS 1.3"
        platformAdmin -> kubernetesAPI "Configures platform via" "HTTPS/443"

        # Dashboard → Kubeflow
        odhDashboard -> kubernetesAPI "Creates Notebook CRs via" "HTTPS/443"

        # Internal interactions
        kfController -> kubernetesAPI "CRUD: StatefulSets, Services, Events" "HTTPS/443 SA token"
        odhController -> kubernetesAPI "CRUD: HTTPRoutes, NetworkPolicies, RBAC, Secrets, ConfigMaps" "HTTPS/443 SA token"
        kfController -> kubernetesAPI "Idle detection: polls notebook kernels/terminals" "HTTP/8888"
        mutatingWebhook -> kubernetesAPI "Called during admission" "HTTPS/8443"
        validatingWebhook -> kubernetesAPI "Called during admission" "HTTPS/8443"

        # External dependencies
        odhController -> gatewayAPI "Creates HTTPRoutes referencing" "Gateway API"
        odhController -> openshiftImageRegistry "Resolves ImageStream tags to digests" "HTTPS/443"
        odhController -> openshiftServiceCA "Auto-provisions TLS certs via annotations" "Annotation-based"
        odhController -> dataSciencePipelines "Discovers DSPA for Elyra config" "HTTPS/443"
        odhController -> mlflowOperator "References ClusterRole for notebook RoleBindings" "ClusterRole ref"
        odhController -> feastIntegration "Mounts Feast ConfigMap when label present" "Label-driven"
        kfController -> istio "Creates VirtualServices (Kubeflow overlay only)" "HTTPS/443"
        prometheus -> kfController "Scrapes metrics" "HTTP/8080"
        prometheus -> odhController "Scrapes metrics" "HTTP/8080"

        # Gateway flow
        gatewayAPI -> kubeflow "Routes /notebook/{ns}/{name} to kube-rbac-proxy" "HTTPS/8443"
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
                background #438dd5
                color #ffffff
            }
        }
    }
}
