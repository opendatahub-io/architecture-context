workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Monitors ML models for fairness and bias"
        admin = person "Platform Administrator" "Deploys and configures TrustyAI services"

        trustyai = softwareSystem "TrustyAI Service Operator" "Manages deployment and lifecycle of TrustyAI explainability services for AI/ML model monitoring and bias detection" {
            operator = container "Operator Controller Manager" "Reconciles TrustyAIService CRs and manages service deployments" "Go Operator" {
                tags "Internal"
            }
            trustyaiService = container "TrustyAI Service" "Provides explainability and fairness metrics analysis" "Quarkus Application" {
                tags "Internal"
            }
            oauthProxy = container "OAuth Proxy Sidecar" "Provides OpenShift OAuth authentication" "OAuth Proxy" {
                tags "Internal"
            }
        }

        k8s = softwareSystem "Kubernetes / OpenShift" "Container orchestration platform" {
            tags "External Platform"
        }
        kserve = softwareSystem "KServe" "Serverless ML inference platform" {
            tags "Internal RHOAI"
        }
        modelmesh = softwareSystem "ModelMesh Serving" "Multi-model serving system" {
            tags "Internal RHOAI"
        }
        prometheus = softwareSystem "Prometheus" "Monitoring and alerting system" {
            tags "External Platform"
        }
        oauth = softwareSystem "OpenShift OAuth" "Authentication service" {
            tags "External Platform"
        }
        database = softwareSystem "External Database" "PostgreSQL, MariaDB, or MySQL for data storage" {
            tags "External"
        }

        # User interactions
        user -> trustyaiService "Views fairness metrics and explainability data" "HTTPS/443 via OAuth"
        admin -> k8s "Creates TrustyAIService custom resources" "kubectl/oc CLI"

        # Operator interactions
        operator -> k8s "Watches TrustyAIService CRs and manages resources" "HTTPS/443 K8s API"
        operator -> kserve "Patches InferenceServices to inject payload processors" "HTTPS/443 K8s API"
        operator -> modelmesh "Patches ModelMesh deployments with payload processor config" "HTTPS/443 K8s API"

        # TrustyAI Service interactions
        kserve -> trustyaiService "Sends inference payloads for analysis" "HTTPS/443 mTLS"
        modelmesh -> trustyaiService "Sends payload data for monitoring" "HTTPS/443 mTLS"
        trustyaiService -> database "Stores inference data and metrics" "PostgreSQL/MySQL Protocol TLS"
        trustyaiService -> prometheus "Exposes fairness metrics (SPD, DIR)" "HTTP/80"

        # OAuth flow
        oauthProxy -> oauth "Validates user authentication tokens" "HTTPS/443"
        oauthProxy -> trustyaiService "Proxies authenticated requests" "HTTP/8080 localhost"

        # Monitoring
        prometheus -> trustyaiService "Scrapes metrics via ServiceMonitor" "HTTP/80"

        # Deployments
        deploymentEnvironment "Production" {
            deploymentNode "RHOAI / ODH Cluster" {
                deploymentNode "Operator Namespace" {
                    containerInstance operator
                }
                deploymentNode "User Namespace" {
                    deploymentNode "TrustyAI Service Pod" {
                        containerInstance trustyaiService
                        containerInstance oauthProxy
                    }
                }
            }
        }
    }

    views {
        systemContext trustyai "SystemContext" {
            include *
            autoLayout
        }

        container trustyai "Containers" {
            include *
            autoLayout
        }

        deployment trustyai "Production" "Deployment" {
            include *
            autoLayout
        }

        styles {
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "External" {
                background #666666
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "Internal" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}
