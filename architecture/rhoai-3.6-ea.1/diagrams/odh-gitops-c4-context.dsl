workspace {
    model {
        platformAdmin = person "Platform Admin" "Deploys and configures RHOAI/ODH platform on Kubernetes clusters"

        odhGitops = softwareSystem "odh-gitops" "GitOps configuration repository providing Helm charts and Kustomize manifests for deploying RHOAI/ODH platform dependencies" {
            ocpChart = container "rhai-on-openshift-chart" "Helm chart for OLM-based RHOAI deployment on OpenShift with DSC/DSCI configuration" "Helm Chart"
            xksChart = container "rhai-on-xks-chart" "Helm chart for non-OpenShift deployment (EKS, AKS, CoreWeave) with bundled dependencies" "Helm Chart"
            kustomizeSubs = container "operator-subscriptions" "OLM Subscription manifests for platform dependency operators" "Kustomize Components"
            kustomizeConfigs = container "operator-configurations" "Post-install configuration CRs for dependency operators" "Kustomize Resources"
        }

        odhOperator = softwareSystem "OpenDataHub Operator" "Platform operator managing DSC and DSCI resources for all RHOAI components" "Internal ODH"
        certManager = softwareSystem "cert-manager Operator" "TLS certificate provisioning for platform components" "External"
        rhclOperator = softwareSystem "RHCL Operator (Kuadrant)" "API gateway policy management and rate limiting" "External"
        sailOperator = softwareSystem "Sail Operator" "Istio service mesh for Gateway API on non-OpenShift clusters" "External"
        kueueOperator = softwareSystem "Kueue Operator" "Job queuing and resource quota management" "External"
        jobSetOperator = softwareSystem "JobSet Operator" "JobSet orchestration for training workloads" "External"
        observability = softwareSystem "Cluster Observability Operator" "Platform monitoring infrastructure" "External"
        opentelemetry = softwareSystem "OpenTelemetry Product" "Distributed tracing instrumentation" "External"
        tempoProduct = softwareSystem "Tempo Product" "Trace storage and query backend" "External"
        olm = softwareSystem "Operator Lifecycle Manager" "Operator deployment and lifecycle management on OpenShift" "External"
        gatewayAPI = softwareSystem "OpenShift Gateway API" "Ingress routing for KServe inference and MaaS endpoints" "External"
        authorino = softwareSystem "Authorino" "TLS bootstrap for authentication on Gateway resources" "External"
        marketplace = softwareSystem "OpenShift Marketplace" "Catalog source for OLM operator subscriptions" "External"

        platformAdmin -> odhGitops "Deploys platform using Helm or kubectl apply -k"
        odhGitops -> odhOperator "Configures via DSC and DSCI custom resources"
        odhGitops -> certManager "Deploys via OLM Subscription or Helm sub-chart"
        odhGitops -> rhclOperator "Deploys via OLM Subscription or Helm sub-chart"
        odhGitops -> sailOperator "Deploys via Helm sub-chart (XKS only)"
        odhGitops -> kueueOperator "Deploys via OLM Subscription"
        odhGitops -> jobSetOperator "Deploys via OLM Subscription"
        odhGitops -> observability "Deploys via OLM Subscription"
        odhGitops -> opentelemetry "Deploys via OLM Subscription"
        odhGitops -> tempoProduct "Deploys via OLM Subscription"
        odhGitops -> olm "Subscribes operators via Subscription API"
        odhGitops -> gatewayAPI "Configures Gateway and GatewayClass resources" "HTTPS/443"
        odhGitops -> authorino "Configures TLS bootstrap via Gateway annotations" "TLS"
        odhGitops -> marketplace "Resolves operators from CatalogSources"
    }

    views {
        systemContext odhGitops "SystemContext" {
            include *
            autoLayout
        }

        container odhGitops "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
