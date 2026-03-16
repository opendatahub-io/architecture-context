workspace {
    model {
        datascientist = person "Data Scientist" "Creates and manages Jupyter notebook servers for ML/AI workloads"

        notebookController = softwareSystem "Notebook Controller" "Manages lifecycle of Jupyter notebook server instances as Kubernetes custom resources" {
            controller = container "NotebookReconciler" "Manages Notebook CR lifecycle, creates StatefulSets and Services" "Go Operator" {
                tags "Operator"
            }
            cullingController = container "CullingReconciler" "Monitors notebook activity and culls idle notebooks" "Go Controller" {
                tags "Operator"
            }
            metricsExporter = container "Metrics Collector" "Exposes Prometheus metrics about notebook usage" "Go Exporter" {
                tags "Metrics"
            }
            virtualServiceMgr = container "VirtualService Manager" "Creates Istio VirtualService resources for notebook access" "Go Controller" {
                tags "Operator"
            }
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Provides CRUD operations on Kubernetes resources" "External" {
            tags "Kubernetes"
        }

        istio = softwareSystem "Istio Service Mesh" "Provides traffic management, routing, and mTLS for services" "External" {
            tags "External"
        }

        knativeServing = softwareSystem "Knative Serving" "Not used by Notebook Controller (used by KServe)" "External" {
            tags "External" "NotUsed"
        }

        prometheus = softwareSystem "Prometheus" "Collects and stores metrics from notebook controller" "External" {
            tags "External"
        }

        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for creating and managing notebooks" "Internal ODH" {
            tags "InternalODH"
        }

        notebookImages = softwareSystem "Notebook Image Registry" "Container registry with Jupyter notebook images" "Internal ODH" {
            tags "InternalODH"
        }

        oauthProxy = softwareSystem "OAuth Proxy" "Optional sidecar for notebook authentication" "Internal ODH" {
            tags "InternalODH"
        }

        kubeflowProfiles = softwareSystem "Kubeflow Profiles" "Provides namespace isolation and multi-tenancy" "Internal ODH" {
            tags "InternalODH" "Optional"
        }

        containerRegistry = softwareSystem "Container Registry" "External registry for pulling notebook images" "External" {
            tags "External"
        }

        # Relationships
        datascientist -> odhDashboard "Creates and manages notebooks via web UI"
        odhDashboard -> k8sAPI "Creates Notebook CRs via" "HTTPS/443 TLS1.2+"

        controller -> k8sAPI "Watches Notebook CRs, creates StatefulSets, Services" "HTTPS/443 TLS1.2+ ServiceAccount Token"
        controller -> virtualServiceMgr "Triggers VirtualService creation when USE_ISTIO=true"
        virtualServiceMgr -> istio "Creates VirtualService CRDs" "Kubernetes API"

        cullingController -> k8sAPI "Queries notebook services for activity via" "HTTP/80"
        cullingController -> k8sAPI "Scales idle StatefulSets to 0" "HTTPS/443 TLS1.2+"

        metricsExporter -> prometheus "Exposes metrics" "HTTP/8080"

        k8sAPI -> controller "Sends watch events for Notebook CRs"
        k8sAPI -> containerRegistry "Pulls notebook images from" "HTTPS/443 TLS1.2+"

        datascientist -> istio "Accesses notebooks via Istio Gateway" "HTTPS/443 TLS1.2+"
        istio -> k8sAPI "Routes traffic to Notebook Services" "HTTP/80 mTLS"

        controller -> notebookImages "References images in Notebook specs"
        k8sAPI -> oauthProxy "Deploys as sidecar (OpenShift variant)"
        controller -> kubeflowProfiles "Integrates with profiles (Kubeflow variant)"
    }

    views {
        systemContext notebookController "NotebookControllerContext" {
            include *
            autoLayout
        }

        container notebookController "NotebookControllerContainers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "InternalODH" {
                background #7ed321
                color #ffffff
            }
            element "Kubernetes" {
                background #326ce5
                color #ffffff
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "Metrics" {
                background #f5a623
                color #ffffff
            }
            element "NotUsed" {
                background #cccccc
                color #666666
            }
            element "Optional" {
                background #9ed991
                color #ffffff
            }
        }
    }
}
