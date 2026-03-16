workspace {
    model {
        user = person "Data Scientist / Platform Admin" "Creates and manages data science workloads and platform configuration"

        rhodsOperator = softwareSystem "RHODS Operator" "Primary operator for Red Hat OpenShift AI that manages the lifecycle of data science platform components via DataScienceCluster and DSCInitialization custom resources" {
            dscController = container "DataScienceCluster Controller" "Reconciles DataScienceCluster CRs to deploy and manage component lifecycles" "Go Controller"
            dsciController = container "DSCInitialization Controller" "Reconciles DSCInitialization CRs for platform-wide settings" "Go Controller"
            webhookServer = container "Webhook Server" "Validates and mutates DataScienceCluster and DSCInitialization resources" "Go Webhook"
            secretGenerator = container "SecretGenerator Controller" "Generates and manages secrets required by platform components" "Go Controller"
            certGenerator = container "CertConfigmapGenerator Controller" "Generates and manages certificate ConfigMaps for TLS/mTLS" "Go Controller"
            manifestFetcher = container "Manifest Fetcher" "Fetches component manifests from git repos and applies them via kustomize" "Go Service"
        }

        %% External dependencies
        kubernetes = softwareSystem "Kubernetes API Server" "Core orchestration platform" "External"
        openshift = softwareSystem "OpenShift Platform" "Extended Kubernetes with Routes, OAuth, SCC" "External"
        serviceMesh = softwareSystem "Service Mesh Operator (Istio)" "Service mesh for traffic management and mTLS" "External"
        knativeOperator = softwareSystem "Serverless Operator (Knative)" "Serverless autoscaling platform" "External"
        authorino = softwareSystem "Authorino Operator" "External authorization for Service Mesh" "External"
        tekton = softwareSystem "OpenShift Pipelines (Tekton)" "CI/CD pipeline orchestration" "External"
        prometheus = softwareSystem "Prometheus Operator" "Monitoring and alerting" "External"
        certManager = softwareSystem "cert-manager" "Certificate management" "External"
        github = softwareSystem "GitHub" "Source code and manifest repository hosting" "External"

        %% Internal ODH/RHOAI components (managed by operator)
        dashboard = softwareSystem "ODH Dashboard" "Web UI for data science platform" "Internal ODH"
        kserve = softwareSystem "KServe" "Model serving with serverless inference" "Internal ODH"
        modelmesh = softwareSystem "ModelMesh Serving" "Multi-model serving for high-density deployments" "Internal ODH"
        dsp = softwareSystem "Data Science Pipelines" "ML workflow orchestration" "Internal ODH"
        workbenches = softwareSystem "Workbenches" "Jupyter notebook environments and VS Code servers" "Internal ODH"
        codeflare = softwareSystem "CodeFlare" "Distributed ML training orchestration" "Internal ODH"
        ray = softwareSystem "Ray" "Distributed computing framework for ML" "Internal ODH"
        kueue = softwareSystem "Kueue" "Job queueing and resource quota management" "Internal ODH"
        trainingOperator = softwareSystem "Training Operator" "Distributed training for PyTorch, TensorFlow, XGBoost" "Internal ODH"
        trustyai = softwareSystem "TrustyAI" "ML explainability and bias detection" "Internal ODH"

        %% User interactions
        user -> rhodsOperator "Creates DataScienceCluster and DSCInitialization via kubectl/oc"
        user -> dashboard "Accesses data science platform UI" "HTTPS/443"

        %% Operator to external dependencies
        rhodsOperator -> kubernetes "Manages cluster resources" "HTTPS/6443"
        rhodsOperator -> openshift "Creates Routes, integrates with OAuth" "HTTPS/6443"
        rhodsOperator -> serviceMesh "Configures ServiceMeshControlPlane, ServiceMeshMemberRoll" "HTTPS/6443"
        rhodsOperator -> knativeOperator "Creates KnativeServing instances" "HTTPS/6443"
        rhodsOperator -> authorino "Creates AuthConfig for external authorization" "HTTPS/6443"
        rhodsOperator -> tekton "Integrates with Tekton for pipelines" "HTTPS/6443"
        rhodsOperator -> prometheus "Creates ServiceMonitor, PodMonitor, PrometheusRule" "HTTPS/6443"
        rhodsOperator -> certManager "Optional certificate management for KServe" "HTTPS/6443"
        rhodsOperator -> github "Fetches component manifests" "HTTPS/443"

        %% Operator deploys and manages internal components
        rhodsOperator -> dashboard "Deploys and manages" "Kustomize manifests"
        rhodsOperator -> kserve "Deploys and manages" "Kustomize manifests"
        rhodsOperator -> modelmesh "Deploys and manages" "Kustomize manifests"
        rhodsOperator -> dsp "Deploys and manages" "Kustomize manifests"
        rhodsOperator -> workbenches "Deploys and manages" "Kustomize manifests"
        rhodsOperator -> codeflare "Deploys and manages" "Kustomize manifests"
        rhodsOperator -> ray "Deploys and manages" "Kustomize manifests"
        rhodsOperator -> kueue "Deploys and manages" "Kustomize manifests"
        rhodsOperator -> trainingOperator "Deploys and manages" "Kustomize manifests"
        rhodsOperator -> trustyai "Deploys and manages" "Kustomize manifests"

        %% Monitoring
        prometheus -> rhodsOperator "Scrapes metrics" "HTTPS/8443"

        %% Container relationships
        dscController -> manifestFetcher "Uses to fetch manifests"
        dscController -> secretGenerator "Triggers secret generation"
        dscController -> certGenerator "Triggers cert generation"
        dsciController -> secretGenerator "Triggers secret generation"
        dsciController -> certGenerator "Triggers cert generation"
        webhookServer -> kubernetes "Validates admission requests"
    }

    views {
        systemContext rhodsOperator "SystemContext" {
            include *
            autoLayout tb
        }

        container rhodsOperator "Containers" {
            include *
            autoLayout tb
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }

        theme default
    }
}
