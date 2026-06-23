workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Jupyter notebook workbenches via Dashboard or CLI"
        platformAdmin = person "Platform Admin" "Configures RHOAI platform and manages notebook infrastructure"

        kubeflow = softwareSystem "Kubeflow Notebook Controller" "Manages the lifecycle of Jupyter Notebook workbenches on OpenShift, reconciling Notebook CRs into StatefulSets, Services, HTTPRoutes, and authentication sidecars" {
            kfController = container "KF Notebook Controller" "Upstream Kubeflow controller: reconciles Notebook CRs into StatefulSets and Services, manages idle notebook culling via Jupyter API polling" "Go (controller-runtime)"
            odhController = container "ODH Notebook Controller" "RHOAI extension controller: adds Gateway API HTTPRoutes, kube-rbac-proxy auth sidecars, DSPA/MLflow/Feast integration, network policies, CA bundle aggregation" "Go (controller-runtime)"
            mutatingWebhook = container "Mutating Webhook" "Intercepts Notebook create/update to inject sidecars, volumes, env vars, resolve images from ImageStreams" "Go (admission webhook, 8443/TCP)"
            validatingWebhook = container "Validating Webhook" "Validates Notebook updates, prevents MLflow annotation removal on running notebooks" "Go (admission webhook, 8443/TCP)"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API server for all resource CRUD operations" "External"
        gatewayAPI = softwareSystem "data-science-gateway" "Gateway API-based ingress (Envoy) for external access to notebooks" "Internal RHOAI"
        dspa = softwareSystem "Data Science Pipelines" "DataSciencePipelinesApplication for Elyra pipeline integration" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "ML experiment tracking and model registry" "Internal RHOAI"
        imageStreams = softwareSystem "OpenShift ImageStreams" "Container image resolution and discovery for notebook images" "External"
        rhodsOperator = softwareSystem "RHOAI Operator" "Platform operator that deploys notebook controllers via kustomize overlays" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing workbenches and data science projects" "Internal RHOAI"
        feast = softwareSystem "Feast" "Feature store config mounted into notebook pods" "Internal RHOAI"
        certManager = softwareSystem "OpenShift Service CA" "Provides TLS certificates for webhook services" "External"

        # User interactions
        dataScientist -> odhDashboard "Creates/manages notebooks via" "HTTPS"
        dataScientist -> gatewayAPI "Accesses notebook UI via" "HTTPS/443 TLS 1.2+"
        odhDashboard -> k8sAPI "Creates Notebook CRs via" "HTTPS/443"
        platformAdmin -> rhodsOperator "Configures platform via" "HTTPS"

        # Admission flow
        k8sAPI -> mutatingWebhook "Sends admission requests" "HTTPS/8443 TLS"
        k8sAPI -> validatingWebhook "Sends admission requests" "HTTPS/8443 TLS"

        # Controller operations
        kfController -> k8sAPI "Creates StatefulSets, Services; scales idle notebooks" "HTTPS/443 SA token"
        odhController -> k8sAPI "Creates HTTPRoutes, NetworkPolicies, Secrets, RBAC" "HTTPS/443 SA token"
        kfController -> kubeflow "Polls Jupyter API for idle detection" "HTTP/8888"

        # External dependencies
        mutatingWebhook -> imageStreams "Resolves notebook container images" "HTTPS/443"
        odhController -> dspa "Reads DSPA CR for pipeline config and S3 credentials" "CRD Read"
        odhController -> gatewayAPI "Reads Gateway CR for public hostname; HTTPRoutes reference as parent" "CRD Read"
        odhController -> mlflow "Verifies ClusterRole, creates RoleBindings" "RBAC"
        odhController -> feast "Mounts Feast config ConfigMap into notebook pods" "ConfigMap"

        # Platform integration
        rhodsOperator -> kubeflow "Deploys controllers via kustomize" "Deployment"
        certManager -> mutatingWebhook "Provisions webhook TLS cert" "service-serving-cert"

        # Gateway auth flow
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
