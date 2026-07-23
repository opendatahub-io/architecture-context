workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys OGX AI distribution servers on Kubernetes"
        platformAdmin = person "Platform Admin" "Manages ODH/RHOAI platform, enables OGX component"

        ogxOperator = softwareSystem "OGX K8s Operator" "Kubernetes operator managing OGX AI distribution server lifecycle" {
            ogxModule = container "ogx-module" "Platform integration controller that deploys the root OGX operator as an ODH/RHOAI component module" "Go / controller-runtime"
            rootOperator = container "OGX Controller" "Reconciles OGXServer CRs, generates config from declarative providers, deploys and manages server Deployments" "Go / controller-runtime"
            webhook = container "Validating Webhook" "Validates OGXServer CRs: distribution name, provider ID uniqueness, model-provider references" "Go / Admission Webhook"
            configGenerator = container "Config Generator" "Resolves OCI image labels, merges provider specs, generates immutable ConfigMaps" "Go"
            secretResolver = container "Secret Resolver" "Collects provider secret references, generates OGX_<PROVIDER_ID>_<FIELD> env vars" "Go"
        }

        ogxServer = softwareSystem "OGX Distribution Server" "AI distribution server instance managed by the operator" "Managed"

        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that manages ODH/RHOAI component lifecycle" "Internal Platform"
        ociRegistry = softwareSystem "OCI Container Registry" "Hosts distribution container images with base config in OCI labels" "External"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane API" "External"
        openshiftAPI = softwareSystem "OpenShift API Server" "Provides cluster TLS security profile configuration" "External"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting platform" "External"
        certManager = softwareSystem "cert-manager / OpenShift service-ca" "Provisions TLS certificates for webhook server" "External"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Sidecar that authenticates and authorizes metrics scraping" "External"
        redis = softwareSystem "Redis" "Optional KV storage backend for OGX server" "External Optional"
        postgresql = softwareSystem "PostgreSQL" "Optional SQL storage backend for OGX server" "External Optional"

        # Relationships - Users
        dataScientist -> ogxOperator "Creates OGXServer CRs via kubectl" "HTTPS/443"
        platformAdmin -> rhodsOperator "Enables OGX component"

        # Relationships - Platform tier
        rhodsOperator -> ogxOperator "Creates OGX CR to enable module" "CRD Watch"
        ogxModule -> rootOperator "Deploys via kustomize manifests" "Kubernetes API"
        ogxModule -> kubernetesAPI "Apply operator resources, watch OGX/OGXServer CRs" "HTTPS/443"

        # Relationships - Internal
        rootOperator -> webhook "Validates CRs on create/update" "HTTPS/9443"
        rootOperator -> configGenerator "Generates server configuration" "In-process"
        rootOperator -> secretResolver "Resolves provider secrets" "In-process"

        # Relationships - Operator to external
        rootOperator -> kubernetesAPI "CRUD for all managed resources" "HTTPS/443"
        rootOperator -> openshiftAPI "Fetch TLS security profile" "HTTPS/443"
        configGenerator -> ociRegistry "Fetch distribution image labels for base config" "HTTPS/443"
        rootOperator -> ogxServer "Health check /v1/health, provider info /v1/providers" "HTTP/8321"

        # Relationships - Managed server
        ogxServer -> redis "KV storage (optional)" "TCP/6379"
        ogxServer -> postgresql "SQL storage (optional)" "TCP/5432"

        # Relationships - Monitoring
        prometheus -> ogxOperator "Scrapes metrics via ServiceMonitor" "HTTPS/8443"
        ogxOperator -> kubeRBACProxy "Authenticates metrics requests" "TokenReview"
        certManager -> ogxOperator "Provisions webhook TLS certificate" "Secret"
    }

    views {
        systemContext ogxOperator "SystemContext" {
            include *
            autoLayout
        }

        container ogxOperator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Optional" {
                background #cccccc
                color #333333
                shape RoundedBox
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Managed" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
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
    }
}
