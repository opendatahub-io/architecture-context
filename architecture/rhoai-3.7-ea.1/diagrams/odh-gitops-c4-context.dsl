workspace "odh-gitops" "GitOps configuration repository for ODH/RHOAI operator, dependencies and post-install configuration (RHOAI 3.7-ea.1)" {
    model {
        admin = person "Platform Administrator" "Installs RHOAI and its prerequisites with kubectl, helm or Argo CD"
        client = person "Model Consumer" "Calls inference APIs through MaaS or inference gateways"

        odhGitops = softwareSystem "odh-gitops" "Kustomize layers and Helm charts that install the ODH/RHOAI operator, its dependency operators and post-install CRs" {
            kustomize = container "Kustomize tree" "components/operators, dependencies/operators, configurations: Namespace, OperatorGroup, Subscription, operator CRs" "Kustomize"
            ocpChart = container "rhai-on-openshift-chart" "OLM Subscriptions, default-dsci/default-dsc, KServe and MaaS Gateways, Authorino config, Perses dashboard; tri-state dependency resolution" "Helm chart 3.6.0"
            gridGateway = container "grid-gateway" "AI Grid consumer gateway: TLS 8443, routes by model name to peer sites, metrics 9443" "Praxis proxy (Rust, third-party image)"
            gridProvider = container "grid-provider-gateway" "AI Grid provider gateway: mTLS 8080 with named client certs, passthrough Route" "Praxis proxy (Rust, third-party image)"
            gridEnrollment = container "grid-enrollment" "Grid CA, site identities, CA bootstrap Job, ACM enrollment Policies" "Helm subchart"
            o11y = container "ai-grid-o11y-hub / spoke" "Hub usage-log LokiStack; spoke ACM ScrapeConfig and NetworkPolicy" "Helm subcharts"
            xksChart = container "rhai-on-xks-chart" "Non-OLM install for AKS/EKS/CoreWeave: CRDs, RBAC, hook Jobs, pull secrets, vendored operator charts" "Helm chart"
            rhaiOperator = container "rhai-operator" "opendatahub-operator image in XKS mode (KServe, AIGateway); webhook 9443, metrics 8080 HTTP" "Go operator"
            cloudManager = container "cloud-manager-operator" "AWS/Azure/CoreWeave: reconciles KubernetesEngine CR to install cert-manager, Gateway API, Sail, LWS, RHCL" "Go operator"
            scripts = container "scripts" "Dependency verification, CRD wait, Authorino TLS prep, uninstall cleanup" "Bash"
        }

        argocd = softwareSystem "Argo CD / OpenShift GitOps" "Syncs the repository into the cluster" "External"
        olm = softwareSystem "OLM and Operator Catalogs" "redhat-operators, certified-operators, community-operators" "External"
        rhods = softwareSystem "rhods-operator / opendatahub-operator" "RHOAI platform operator reconciling DSCI and DSC" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving behind openshift-ai-inference Gateway" "Internal RHOAI"
        aigateway = softwareSystem "AIGateway (MaaS)" "Models-as-a-Service gateway and policies" "Internal RHOAI"
        depOperators = softwareSystem "Dependency operators" "cert-manager, Kueue, LWS, JobSet, RHCL, COO, OpenTelemetry, Tempo, Loki, CMA, NFD, NVIDIA GPU, Agent Sandbox, MariaDB" "External"
        authorino = softwareSystem "RHCL Authorino / Kuadrant" "Gateway authentication and rate limiting" "External"
        certManager = softwareSystem "cert-manager" "Issues Grid CA, site identities and XKS certificates" "External"
        acm = softwareSystem "Red Hat ACM" "Multi-cluster Policies, Placement, metrics federation" "External"
        peerSites = softwareSystem "Peer AI Grid sites" "Other clusters in the Grid trust domain" "External"
        hubLoki = softwareSystem "Hub LokiStack + NooBaa S3" "AI Grid usage-log store" "External"
        oidc = softwareSystem "OIDC issuer" "Keycloak / Entra ID for XKS platform auth gateway" "External"
        registries = softwareSystem "Container registries" "registry.redhat.io, quay.io, ghcr.io" "External"
        konflux = softwareSystem "Konflux" "CI validation and image digest substitution" "External"

        admin -> kustomize "kubectl apply -k" "HTTPS/6443"
        admin -> ocpChart "helm install / upgrade" "HTTPS/6443"
        admin -> xksChart "helm install" "HTTPS/443"
        argocd -> kustomize "Syncs" "Git"
        argocd -> ocpChart "Syncs (skipCrdCheck)" "Git"

        kustomize -> olm "Creates Subscriptions / OperatorGroups"
        ocpChart -> olm "Creates Subscriptions (DISABLE_DSC_CONFIG=true)"
        olm -> rhods "Installs"
        olm -> depOperators "Installs"
        ocpChart -> rhods "Creates default-dsci / default-dsc" "HTTPS/6443"
        ocpChart -> kserve "Creates openshift-ai-inference Gateway"
        ocpChart -> aigateway "Creates maas-default-gateway and Route"
        ocpChart -> authorino "Creates Kuadrant/Authorino CRs; SSA CA patch"
        ocpChart -> gridGateway "Renders when aiGrid Managed"
        ocpChart -> gridProvider "Renders for ai-grid-inference/combined"
        ocpChart -> gridEnrollment "Renders"
        ocpChart -> o11y "Renders"

        client -> aigateway "Inference requests" "HTTPS/443 Bearer"
        aigateway -> gridGateway "Forwards model requests (Authorization stripped)" "HTTPS/443->8443 TLS"
        gridGateway -> peerSites "Cross-site inference" "HTTPS/443 mTLS Grid CA"
        peerSites -> gridProvider "Cross-site inference via passthrough Route" "HTTPS/443->8080 mTLS"
        gridProvider -> kserve "Local inference (grid-model-client-token)" "HTTPS/443 Bearer"
        gridEnrollment -> certManager "Issuer / Certificate CRs"
        gridEnrollment -> acm "Policy / Placement for enrollment"
        o11y -> acm "ScrapeConfig (collector 8890 HTTP)"
        o11y -> hubLoki "Usage logs OTLP" "HTTPS/443 Bearer"

        xksChart -> rhaiOperator "Deploys"
        xksChart -> cloudManager "Deploys"
        cloudManager -> rhaiOperator "Provisions webhook cert"
        client -> xksChart "Calls inference-gateway" "HTTP/80, HTTPS/443"
        rhaiOperator -> oidc "Platform auth gateway (kube-auth-proxy)" "HTTPS/443"
        rhaiOperator -> registries "Image pulls (rhai-pull-secret)" "HTTPS/443"
        konflux -> odhGitops "Validates on HyperShift; substitutes digests"
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
            element "Person" {
                shape person
                background #08427b
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
        }
    }
}
