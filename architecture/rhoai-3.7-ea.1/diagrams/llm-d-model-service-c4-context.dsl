workspace "llm-d-model-service" "C4 context for the llm-d ModelService controller (RHOAI 3.7-ea.1; upstream deprecated)" {
    model {
        modelOwner = person "Model Owner" "Creates ModelService CRs to serve a base model"
        platformAdmin = person "Platform Admin" "Authors BaseConfig presets, installs the controller, supplies EPP_CLUSTER_ROLE and pull secrets"
        inferenceClient = person "Inference Client" "Sends inference requests through the Gateway"

        modelService = softwareSystem "llm-d-model-service" "Kubebuilder controller that reconciles ModelService CRs into a full llm-d inference stack" {
            manager = container "manager CLI" "Cobra root command with run and generate sub-commands; requires --epp-cluster-role" "Go"
            reconciler = container "ModelServiceReconciler" "Interpolates BaseConfig + ModelService (Sprig), merges with mergo, CreateOrUpdate children, updates status" "Go, controller-runtime v0.20.4"
            generator = container "manager generate" "Offline render of child manifests from ModelService + BaseConfig YAML" "Go CLI"
            metricsServer = container "Metrics server" "controller-runtime Prometheus metrics; TokenReview/SAR auth" "HTTPS 8443"
            probes = container "Health probes" "/healthz, /readyz (unauthenticated)" "HTTP 8081"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Stores ModelService, BaseConfig ConfigMaps and all child resources" "External"
        gatewayApi = softwareSystem "Gateway API + Gateway implementation" "Serves HTTPRoutes attached via gatewayRefs" "External"
        gie = softwareSystem "Gateway API Inference Extension" "InferencePool / InferenceModel v1alpha2 CRDs" "External"
        prometheus = softwareSystem "Prometheus" "Scrapes controller metrics" "External"
        huggingFace = softwareSystem "HuggingFace / OCI registries" "Model artifact sources (hf://, oci://)" "External"

        epp = softwareSystem "llm-d-inference-scheduler (EPP)" "Endpoint picker for the InferencePool; ext-proc gRPC 9002" "Internal RHOAI"
        vllm = softwareSystem "llm-d vLLM model servers" "Prefill/decode Deployments (+ llm-d-routing-sidecar on decode)" "Internal RHOAI"
        deployer = softwareSystem "llm-d-deployer" "Installs the controller and BaseConfig presets" "Internal RHOAI"
        helmChart = softwareSystem "llm-d-modelservice Helm chart" "Successor (llm-d-incubation) replacing this operator" "Internal RHOAI"

        modelOwner -> k8sApi "Creates ModelService" "HTTPS/6443"
        platformAdmin -> k8sApi "Creates BaseConfig ConfigMaps" "HTTPS/6443"
        deployer -> modelService "Installs controller and presets"
        reconciler -> k8sApi "Watches + CRUD on ModelService, Deployments, Services, SAs, RoleBindings, ConfigMaps, HTTPRoutes, GIE objects" "HTTPS/6443, SA token"
        metricsServer -> k8sApi "TokenReview + SubjectAccessReview" "HTTPS/6443"
        manager -> reconciler "Starts (run)"
        manager -> generator "Starts (generate)"
        reconciler -> gatewayApi "Creates HTTPRoute (parentRefs = gatewayRefs)" "Kubernetes API"
        reconciler -> gie "Creates InferencePool and InferenceModel" "Kubernetes API"
        reconciler -> epp "Deploys EPP Deployment, Service, SA, RoleBinding" "Kubernetes API"
        reconciler -> vllm "Deploys prefill/decode Deployments and Services" "Kubernetes API"
        prometheus -> metricsServer "Scrapes /metrics" "HTTPS/8443, Bearer token"

        inferenceClient -> gatewayApi "Inference request" "HTTP/HTTPS per Gateway"
        gatewayApi -> epp "Endpoint selection" "gRPC ext-proc/9002"
        gatewayApi -> vllm "Routes to selected decode pod" "HTTP/8000"
        vllm -> huggingFace "Downloads model artifacts" "HTTPS/443, HF_TOKEN"
        helmChart -> modelService "Supersedes"
    }

    views {
        systemContext modelService "SystemContext" {
            include *
            autoLayout
        }

        container modelService "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
        }
    }
}
