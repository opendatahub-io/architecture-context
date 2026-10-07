workspace {
    model {
        clusterAdmin = person "Cluster Admin" "Deploys and manages the ODH/RHOAI platform"
        dataSci = person "Data Scientist" "Creates notebooks, pipelines, and deploys models"

        odhManifests = softwareSystem "odh-manifests" "Central Kustomize manifest repository packaging deployment definitions for all ODH/RHOAI platform components" {
            kfdefProfiles = container "KfDef Profiles" "Deployment profiles composing component subsets (odh-core, model-serving)" "KfDef YAML"
            kserveBundle = container "KServe Bundle" "Monolithic 19K-line manifest with 4 CRDs, controller, RBAC, webhooks" "Kustomize Base"
            modelMeshManifests = container "ModelMesh Manifests" "Controller deployment and 4 ClusterServingRuntime definitions" "Kustomize Overlay"
            modelController = container "odh-model-controller Manifests" "3-replica HA controller for model serving orchestration" "Kustomize Base"
            dashboardManifests = container "Dashboard Manifests" "ODH Dashboard with RHOAI rebranding overlay and serving templates" "Kustomize Overlay"
            dspoManifests = container "DSPO Manifests" "Data Science Pipelines Operator CRDs and controller" "Kustomize Base"
            notebookManifests = container "Notebook Controller Manifests" "Kubeflow and ODH notebook controller CRDs and deployment" "Kustomize Base"
            trustyaiManifests = container "TrustYAI Manifests" "TrustYAI service operator CRDs and deployment" "Kustomize Base"
            monitoringManifests = container "Monitoring Manifests" "Prometheus, Grafana, and alerting stack" "Kustomize Base"
            containerImage = container "Manifest Container Image" "UBI-based image packaging all manifests as tar.gz" "Dockerfile"
        }

        kustomize = softwareSystem "Kustomize" "Manifest rendering and overlay composition engine" "External Tool"
        kfdefOperator = softwareSystem "KfDef Operator" "Deployment orchestration using KfDef custom resources" "External"
        openshift = softwareSystem "OpenShift" "Container platform with Routes, OAuth, Templates, SCCs" "External"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh for traffic management and mTLS" "External"
        certManager = softwareSystem "cert-manager" "Webhook certificate management" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "External"
        imageRegistry = softwareSystem "Container Image Registry" "quay.io / registry.redhat.io for component images" "External"

        clusterAdmin -> odhManifests "Selects KfDef profile and deploys"
        clusterAdmin -> kfdefOperator "Applies KfDef CR via kubectl"
        kfdefOperator -> odhManifests "Fetches and renders manifests" "HTTPS/443"
        kfdefOperator -> openshift "Applies rendered resources" "HTTPS/6443"

        odhManifests -> kustomize "Uses for manifest rendering"
        odhManifests -> openshift "Targets for deployment"
        odhManifests -> istio "Configures service mesh integration"
        odhManifests -> certManager "References for webhook certificates"

        containerImage -> imageRegistry "Published to" "HTTPS/443"
        kfdefOperator -> containerImage "Pulls manifest archive" "HTTPS/443"

        kfdefProfiles -> kserveBundle "Composes"
        kfdefProfiles -> modelMeshManifests "Composes"
        kfdefProfiles -> dashboardManifests "Composes"
        kfdefProfiles -> dspoManifests "Composes"
        kfdefProfiles -> notebookManifests "Composes"
        kfdefProfiles -> monitoringManifests "Composes"

        prometheus -> modelController "Scrapes metrics" "HTTP/8080 via kube-rbac-proxy"

        dataSci -> dashboardManifests "Uses dashboard deployed from these manifests"
    }

    views {
        systemContext odhManifests "SystemContext" {
            include *
            autoLayout
        }

        container odhManifests "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Tool" {
                background #bbbbbb
                color #333333
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
    }
}
