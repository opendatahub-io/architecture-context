workspace {
    model {
        admin = person "Platform Admin" "Configures and manages the RHOAI platform via DSC/DSCI CRs"
        datascientist = person "Data Scientist" "Uses RHOAI platform services (notebooks, model serving, pipelines)"

        rhodsOperator = softwareSystem "rhods-operator" "Central control plane for RHOAI — orchestrates 16+ component operators, manages ingress, auth, monitoring" {
            manager = container "manager" "Primary operator binary managing DSC, DSCI, component, service, and gateway controllers" "Go Operator (controller-runtime)" {
                dscController = component "DSC Controller" "Orchestrates component CRs from DataScienceCluster spec" "Controller"
                dsciController = component "DSCI Controller" "Initializes platform services (auth, monitoring, gateway, cert config)" "Controller"
                gatewayController = component "Gateway Controller" "Deploys full ingress stack: Gateway API, Envoy, kube-auth-proxy, Routes" "Controller"
                authController = component "Auth Controller" "Manages RBAC groups, roles, bindings for platform admin/allowed groups" "Controller"
                monitoringController = component "Monitoring Controller" "Deploys Prometheus MonitoringStack, Tempo, OTel, Perses" "Controller"
                certConfigMap = component "CertConfigMap Generator" "Propagates trusted CA bundles to all namespaces" "Controller"
                modulesController = component "Modules Controller" "Manages out-of-tree component operators via Helm/Kustomize" "Controller"
                componentControllers = component "Component Controllers (16)" "Per-component controllers for Dashboard, KServe, Kueue, DSP, Workbenches, etc." "Controllers"
            }
            cloudmanager = container "cloudmanager" "Multi-cloud infrastructure dependency manager for AWS, Azure, CoreWeave via Helm charts" "Go Operator (controller-runtime)"
            kubeAuthProxy = container "kube-auth-proxy" "OAuth2/OIDC authentication proxy for Gateway traffic" "oauth2-proxy"
            envoyDataPlane = container "Envoy Data Plane" "Gateway API Envoy proxy with ext_authz and Lua filters" "Envoy"
        }

        # Internal Platform Components (managed by rhods-operator)
        dashboard = softwareSystem "Dashboard" "RHOAI web console" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Batch scheduling and resource management" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration (Argo-based)" "Internal RHOAI"
        workbenches = softwareSystem "Workbenches" "Jupyter notebook environments" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "ML model metadata registry" "Internal RHOAI"
        ray = softwareSystem "Ray (KubeRay)" "Distributed compute framework" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "AI evaluation and guardrails" "Internal RHOAI"
        maas = softwareSystem "Models as Service" "API key and OIDC-based model serving" "Internal RHOAI"
        trainingOp = softwareSystem "Training Operator" "Kubeflow training operator" "Internal RHOAI"
        trainer = softwareSystem "Trainer" "JobSet-based training" "Internal RHOAI"
        feast = softwareSystem "Feast Operator" "Feature store operator" "Internal RHOAI"
        ogx = softwareSystem "OGX" "OGX operator (LlamaStack replacement)" "Internal RHOAI"
        mlflow = softwareSystem "MLflow Operator" "Experiment tracking" "Internal RHOAI"
        spark = softwareSystem "Spark Operator" "Spark workload management" "Internal RHOAI"
        modelController = softwareSystem "Model Controller" "KServe/ModelRegistry orchestration" "Internal RHOAI"

        # External Dependencies
        k8sApi = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "Integrated OAuth server for authentication" "External"
        oidcProvider = softwareSystem "External OIDC Provider" "External identity provider" "External"
        openshiftApi = softwareSystem "OpenShift API" "Platform API for TLS profiles, auth config" "External"
        olm = softwareSystem "Operator Lifecycle Manager" "Operator installation and upgrades" "External"
        gatewayApi = softwareSystem "Gateway API" "Kubernetes Gateway API CRDs" "External"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh for traffic management" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management" "External"
        prometheusOp = softwareSystem "Prometheus Operator" "Monitoring stack management" "External"
        otelOp = softwareSystem "OpenTelemetry Operator" "Distributed tracing and instrumentation" "External"
        tempoOp = softwareSystem "Tempo Operator" "Trace storage and querying" "External"
        lwsOp = softwareSystem "LeaderWorkerSet Operator" "Distributed workload management" "External"

        # Relationships - Admin
        admin -> rhodsOperator "Creates DSC/DSCI CRs via kubectl" "HTTPS/6443"
        datascientist -> envoyDataPlane "Accesses platform services" "HTTPS/443"

        # Relationships - Operator → Components
        rhodsOperator -> dashboard "Deploys and manages" "K8s API"
        rhodsOperator -> kserve "Deploys and manages" "K8s API"
        rhodsOperator -> kueue "Deploys and manages" "K8s API"
        rhodsOperator -> dsp "Deploys and manages" "K8s API"
        rhodsOperator -> workbenches "Deploys and manages" "K8s API"
        rhodsOperator -> modelRegistry "Deploys and manages" "K8s API"
        rhodsOperator -> ray "Deploys and manages" "K8s API"
        rhodsOperator -> trustyai "Deploys and manages" "K8s API"
        rhodsOperator -> maas "Deploys and manages" "K8s API"
        rhodsOperator -> trainingOp "Deploys and manages" "K8s API"
        rhodsOperator -> trainer "Deploys and manages" "K8s API"
        rhodsOperator -> feast "Deploys and manages" "K8s API"
        rhodsOperator -> ogx "Deploys and manages" "K8s API"
        rhodsOperator -> mlflow "Deploys and manages" "K8s API"
        rhodsOperator -> spark "Deploys and manages" "K8s API"
        rhodsOperator -> modelController "Deploys and manages" "K8s API"

        # Relationships - Operator → External
        rhodsOperator -> k8sApi "CRD watches, resource CRUD" "HTTPS/6443"
        rhodsOperator -> openshiftOAuth "OAuthClient management" "HTTPS/443"
        rhodsOperator -> oidcProvider "OIDC authentication" "HTTPS/443"
        rhodsOperator -> openshiftApi "TLS security profile, cluster auth" "HTTPS/6443"
        rhodsOperator -> olm "CSV lifecycle management" "K8s API"
        rhodsOperator -> gatewayApi "Gateway, HTTPRoute management" "K8s API"
        rhodsOperator -> istio "EnvoyFilter, DestinationRule" "K8s API"
        rhodsOperator -> certManager "TLS certificate issuance" "K8s API"
        rhodsOperator -> prometheusOp "MonitoringStack, ServiceMonitor" "K8s API"
        rhodsOperator -> otelOp "OpenTelemetryCollector, Instrumentation" "K8s API"
        rhodsOperator -> tempoOp "TempoMonolithic, TempoStack" "K8s API"

        # Cloud manager relationships
        cloudmanager -> certManager "Deploys via Helm" "K8s API"
        cloudmanager -> istio "Deploys Sail operator via Helm" "K8s API"
        cloudmanager -> lwsOp "Deploys via Helm" "K8s API"
        cloudmanager -> gatewayApi "Deploys CRDs via Helm" "K8s API"

        # Auth flow
        envoyDataPlane -> kubeAuthProxy "ext_authz authentication" "HTTPS/8443"
        kubeAuthProxy -> openshiftOAuth "Token validation" "HTTPS/443"
        kubeAuthProxy -> oidcProvider "OIDC validation" "HTTPS/443"
    }

    views {
        systemContext rhodsOperator "SystemContext" {
            include *
            autoLayout
        }

        container rhodsOperator "Containers" {
            include *
            autoLayout
        }

        component manager "ManagerComponents" {
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
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
