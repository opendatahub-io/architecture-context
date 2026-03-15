workspace {
    model {
        user = person "Data Scientist / Admin" "Creates and manages data science workloads via web interface"

        odhDashboard = softwareSystem "ODH Dashboard" "Web-based management console for Open Data Hub and Red Hat OpenShift AI platform" {
            frontend = container "Frontend SPA" "User interface for platform management" "React 18 / PatternFly" {
                tags "WebApp"
            }
            backend = container "Backend API" "API server and authentication proxy" "Node.js / Fastify" {
                tags "API"
            }
            proxy = container "OAuth Proxy" "Authentication and authorization" "kube-rbac-proxy" {
                tags "Proxy"
            }

            user -> proxy "Accesses dashboard via HTTPS/443"
            proxy -> backend "Forwards authenticated requests with user headers"
            backend -> frontend "Serves React SPA"
        }

        # External Platform Services
        kubernetes = softwareSystem "Kubernetes API" "Container orchestration and resource management" "External Platform" {
            tags "External"
        }

        openshift = softwareSystem "OpenShift Platform" "Enterprise Kubernetes distribution" "External Platform" {
            oauth = container "OAuth Server" "User authentication service" "OpenShift" {
                tags "External"
            }
            imageRegistry = container "Image Registry" "Container image storage" "OpenShift" {
                tags "External"
            }
            monitoring = container "Monitoring Stack" "Metrics and observability" "Thanos/Prometheus" {
                tags "External"
            }
        }

        # Internal ODH Components
        notebookController = softwareSystem "Notebook Controller" "Manages Jupyter notebook lifecycle" "Internal ODH" {
            tags "Internal"
        }

        kserveController = softwareSystem "KServe Controller" "Model serving infrastructure" "Internal ODH" {
            tags "Internal"
        }

        modelRegistryOp = softwareSystem "Model Registry Operator" "Model metadata and versioning" "Internal ODH" {
            tags "Internal"
        }

        odhOperator = softwareSystem "ODH Operator" "Platform configuration and lifecycle" "Internal ODH" {
            tags "Internal"
        }

        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "ML workflow orchestration" "Internal ODH" {
            tags "Internal"
        }

        feastOperator = softwareSystem "Feast Operator" "Feature store management" "Internal ODH" {
            tags "Internal"
        }

        llamaStackOp = softwareSystem "Llama Stack Operator" "LLM deployment and management" "Internal ODH" {
            tags "Internal"
        }

        # Relationships - User interactions
        user -> odhDashboard "Manages data science projects and workloads via web UI"

        # Relationships - Authentication
        proxy -> oauth "Validates OAuth2 tokens and authenticates users" "HTTPS/443"

        # Relationships - Dashboard to Platform
        backend -> kubernetes "Queries and manages Kubernetes resources" "HTTPS/443 (SA Token)"
        backend -> monitoring "Queries Prometheus metrics" "HTTPS/9092 (SA Token)"
        backend -> imageRegistry "Accesses container images and ImageStreams" "HTTPS/443 (SA Token)"

        # Relationships - Dashboard to ODH Components
        backend -> notebookController "Creates and manages Jupyter notebooks" "K8s API (CRD)"
        backend -> kserveController "Monitors InferenceService status" "K8s API (CRD Watch)"
        backend -> modelRegistryOp "Manages ModelRegistry instances" "K8s API (CRD)"
        backend -> odhOperator "Monitors DataScienceCluster and DSCInitialization" "K8s API (CRD Watch)"
        backend -> kubeflowPipelines "Accesses pipeline definitions and executions" "HTTP API Proxy"
        backend -> feastOperator "Monitors FeatureStore resources" "K8s API (CRD Watch)"
        backend -> llamaStackOp "Monitors LlamaStackDistribution resources" "K8s API (CRD Watch)"

        # Component interactions (controllers)
        notebookController -> kubernetes "Creates notebook pods and services" "K8s API"
        kserveController -> kubernetes "Manages inference service deployments" "K8s API"
        modelRegistryOp -> kubernetes "Manages model registry resources" "K8s API"
        odhOperator -> kubernetes "Manages ODH platform components" "K8s API"
        feastOperator -> kubernetes "Manages feature store deployments" "K8s API"
        llamaStackOp -> kubernetes "Manages LLM deployments" "K8s API"

        # Production deployment environment
        prod = deploymentEnvironment "Production" {
            deploymentNode "OpenShift Cluster" {
                tags "OpenShift"

                deploymentNode "opendatahub / redhat-ods-applications Namespace" {
                    tags "Namespace"

                    deploymentNode "odh-dashboard Pod (x2 replicas)" {
                        tags "Pod"

                        containerInstance proxy
                        containerInstance backend
                        containerInstance frontend
                    }
                }

                deploymentNode "openshift-authentication Namespace" {
                    tags "Namespace"
                    containerInstance oauth
                }

                deploymentNode "openshift-monitoring Namespace" {
                    tags "Namespace"
                    containerInstance monitoring
                }

                deploymentNode "openshift-image-registry Namespace" {
                    tags "Namespace"
                    containerInstance imageRegistry
                }
            }
        }
    }

    views {
        systemContext odhDashboard "SystemContext" {
            include *
            autoLayout lr
        }

        container odhDashboard "Containers" {
            include *
            autoLayout tb
        }

        deployment odhDashboard "Production" "Deployment" {
            include *
            autoLayout lr
        }

        styles {
            element "Person" {
                shape person
                background #1168bd
                color #ffffff
            }

            element "Software System" {
                background #438dd5
                color #ffffff
            }

            element "Container" {
                background #438dd5
                color #ffffff
            }

            element "WebApp" {
                shape WebBrowser
                background #4a90e2
            }

            element "API" {
                shape Hexagon
                background #2874c7
            }

            element "Proxy" {
                shape Pipe
                background #82b366
            }

            element "External" {
                background #999999
                color #ffffff
            }

            element "Internal" {
                background #7ed321
                color #000000
            }

            element "OpenShift" {
                background #cc0000
                color #ffffff
            }

            element "Namespace" {
                background #e8e8e8
                color #000000
            }

            element "Pod" {
                background #d5e8d4
                color #000000
            }

            relationship "Relationship" {
                thickness 2
                fontSize 18
            }
        }

        theme default
    }
}
