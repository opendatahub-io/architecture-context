workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models and monitors them for bias and fairness"
        mlEngineer = person "ML Engineer" "Deploys and manages TrustyAI services for model monitoring"

        trustyai = softwareSystem "TrustyAI Service Operator" "Kubernetes operator that manages deployment and lifecycle of TrustyAI explainability services for model monitoring and bias detection" {
            controller = container "controller-manager" "Operator controller that reconciles TrustyAIService CRs" "Go Operator" {
                reconciler = component "Reconciler" "Watches TrustyAIService CRs and manages lifecycle" "Go Controller"
                deployer = component "Resource Manager" "Creates and updates Deployments, Services, Routes, PVCs" "Go"
                integrator = component "Integration Manager" "Patches KServe/ModelMesh for payload logging" "Go"
            }

            trustyaiService = container "TrustyAI Service Instance" "Managed TrustyAI service for explainability and bias detection" "Quarkus Java" {
                api = component "REST API" "Provides fairness metrics and explainability endpoints" "JAX-RS"
                consumer = component "Payload Consumer" "Ingests prediction payloads from KServe/ModelMesh" "Java"
                metricsEngine = component "Metrics Engine" "Calculates fairness metrics (SPD, DIR)" "Java"
                storage = component "Data Storage" "Persists inference data and metrics" "Filesystem/Database"
            }

            oauthProxy = container "OAuth Proxy" "Protects external access with OpenShift OAuth" "Go Proxy" {
                authHandler = component "Authentication Handler" "Validates OAuth tokens" "Go"
                sarChecker = component "SubjectAccessReview" "Checks Kubernetes RBAC permissions" "Go"
            }
        }

        kubernetes = softwareSystem "Kubernetes / OpenShift" "Container orchestration platform" "External"
        kserve = softwareSystem "KServe" "Serverless ML inference platform" "Internal RHOAI"
        modelmesh = softwareSystem "ModelMesh Serving" "Multi-model serving runtime" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        openShiftOAuth = softwareSystem "OpenShift OAuth" "Authentication service" "External"
        storage = softwareSystem "Persistent Storage" "Kubernetes PersistentVolumes" "External"
        certManager = softwareSystem "cert-manager / service-ca" "TLS certificate provisioning" "External"

        # User interactions
        dataScientist -> trustyai "Monitors model fairness and bias metrics via API"
        mlEngineer -> trustyai "Creates TrustyAIService CRs to deploy monitoring"

        # Operator interactions
        controller -> kubernetes "Manages TrustyAI resources (Deployments, Services, Routes)" "HTTPS/443, RBAC"
        mlEngineer -> kubernetes "Creates TrustyAIService custom resources" "kubectl"
        kubernetes -> controller "Notifies of TrustyAIService CR changes" "Watch API"

        # TrustyAI Service interactions
        dataScientist -> oauthProxy "Accesses TrustyAI API" "HTTPS/443, OAuth Token"
        oauthProxy -> openShiftOAuth "Validates OAuth tokens" "HTTPS/443"
        oauthProxy -> kubernetes "Performs SubjectAccessReview" "HTTPS/443, RBAC"
        oauthProxy -> trustyaiService "Forwards authenticated requests" "HTTP/8080 localhost"

        # Integration with inference platforms
        controller -> kserve "Configures Logger.URL for payload logging" "Kubernetes API, Patch InferenceService"
        controller -> modelmesh "Injects MM_PAYLOAD_PROCESSORS environment variable" "Kubernetes API, Patch Deployment"
        kserve -> trustyaiService "Sends inference payloads for monitoring" "HTTP/80, POST /consumer/kserve/v2"
        modelmesh -> trustyaiService "Sends inference payloads for monitoring" "HTTP/80, POST /consumer/kserve/v2"

        # Monitoring integration
        trustyaiService -> prometheus "Exposes fairness metrics (trustyai_spd, trustyai_dir)" "HTTP/80, /q/metrics"
        prometheus -> trustyaiService "Scrapes metrics" "HTTP/80"

        # Storage integration
        trustyaiService -> storage "Stores inference data and metrics" "Filesystem, PVC mount"

        # TLS provisioning
        certManager -> oauthProxy "Provisions TLS certificates for OAuth service" "service.beta.openshift.io annotation"
    }

    views {
        systemContext trustyai "TrustyAISystemContext" {
            include *
            autoLayout
        }

        container trustyai "TrustyAIContainers" {
            include *
            autoLayout
        }

        component controller "ControllerComponents" {
            include *
            autoLayout
        }

        component trustyaiService "TrustyAIServiceComponents" {
            include *
            autoLayout
        }

        component oauthProxy "OAuthProxyComponents" {
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #f5a623
                color #000000
                shape Person
            }
        }
    }
}
