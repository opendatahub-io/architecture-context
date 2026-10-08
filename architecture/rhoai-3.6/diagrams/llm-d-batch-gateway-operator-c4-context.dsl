workspace {
    model {
        platformAdmin = person "Platform Admin" "Deploys and configures batch inference gateways via LLMBatchGateway CRs"
        dataScientist = person "Data Scientist" "Submits batch inference jobs via the API server"

        batchGatewayOperator = softwareSystem "llm-d-batch-gateway-operator" "Reconciles LLMBatchGateway CRs into batch inference gateway deployments via embedded Helm chart rendering" {
            reconciler = container "LLMBatchGatewayReconciler" "Main reconcile loop: renders Helm charts, applies resources via Server-Side Apply, manages status conditions" "Go (controller-runtime)"
            metricsController = container "MetricsController" "Self-heals operator metrics Service, ServiceMonitor, and PrometheusRule resources" "Go (controller-runtime)"
            helmRenderer = container "HelmRenderer" "Loads and renders embedded batch-gateway and async-processor Helm charts into unstructured Kubernetes objects" "Go (helm.sh/helm/v3)"
            secretSync = container "Secret Sync" "Resolves cross-namespace secrets using Gateway API ReferenceGrant authorization" "Go"
            tlsResolver = container "TLS Profile Resolver" "Reads OpenShift cluster TLS profile at startup, watches for changes, triggers graceful restart" "Go (openshift/controller-runtime-common)"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource CRUD, watches, and RBAC" "External"
        certManager = softwareSystem "cert-manager" "Auto-provisions TLS certificates via Certificate CRs" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute-based ingress and ReferenceGrant cross-namespace authorization" "External"
        prometheusOperator = softwareSystem "prometheus-operator" "Manages ServiceMonitor, PodMonitor, and PrometheusRule CRDs for monitoring" "External"
        openshiftConfig = softwareSystem "OpenShift Config API" "Provides cluster TLS profile configuration (cipher suites, minimum TLS version)" "External"
        serviceCA = softwareSystem "OpenShift service-ca" "Provisions and auto-rotates TLS certificates for Services" "External"
        odhOperator = softwareSystem "opendatahub-operator / ai-gateway-operator" "Deploys and manages this operator via kustomize overlays" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Scrapes operator metrics via ServiceMonitor" "External"

        platformAdmin -> batchGatewayOperator "Creates LLMBatchGateway CRs" "kubectl / GitOps"
        dataScientist -> batchGatewayOperator "Submits batch jobs via rendered API server" "HTTP"

        odhOperator -> batchGatewayOperator "Deploys via kustomize base + overlay" "Kustomize"

        batchGatewayOperator -> kubernetesAPI "CR watches, Server-Side Apply, status patching, TokenReview, SubjectAccessReview" "HTTPS/6443"
        batchGatewayOperator -> certManager "Renders Certificate CRs for API server TLS" "HTTPS/6443 (via K8s API)"
        batchGatewayOperator -> gatewayAPI "Renders HTTPRoutes for ingress; reads ReferenceGrants for secret authorization" "HTTPS/6443 (via K8s API)"
        batchGatewayOperator -> prometheusOperator "Creates ServiceMonitor, PodMonitor, PrometheusRule resources" "HTTPS/6443 (via K8s API)"
        batchGatewayOperator -> openshiftConfig "Reads and watches cluster TLS profile" "HTTPS/6443 (via K8s API)"
        serviceCA -> batchGatewayOperator "Provisions metrics-tls Secret" "service.beta.openshift.io annotation"
        prometheus -> batchGatewayOperator "Scrapes /metrics endpoint" "HTTPS/8443 (Bearer + SAR)"

        reconciler -> helmRenderer "Renders charts with CR spec values"
        reconciler -> secretSync "Resolves cross-namespace secrets"
        reconciler -> kubernetesAPI "Server-Side Apply rendered objects"
        metricsController -> kubernetesAPI "Self-heals monitoring resources"
        tlsResolver -> openshiftConfig "Reads and watches TLS profile"
        tlsResolver -> reconciler "Provides TLS config for Helm values"
        tlsResolver -> metricsController "Provides TLS config for metrics server"
    }

    views {
        systemContext batchGatewayOperator "SystemContext" {
            include *
            autoLayout
        }

        container batchGatewayOperator "Containers" {
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
            element "Person" {
                shape person
                background #4a90e2
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
        }
    }
}
