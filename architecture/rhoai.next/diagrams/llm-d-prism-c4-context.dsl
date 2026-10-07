workspace {
    model {
        platformEngineer = person "AI Platform Engineer" "Chooses and configures inference infrastructure using benchmark data"
        mlEngineer = person "ML Engineer" "Analyzes inference performance and submits benchmark results"

        prism = softwareSystem "Prism" "Interactive performance analysis dashboard for distributed AI inference systems" {
            reactFrontend = container "React Frontend" "Single-page application with interactive dashboards, scatter plots, comparison charts, and Results Store UI" "React 19, Vite 7, Recharts, Tailwind CSS"
            expressBFF = container "Express Backend (BFF)" "Proxies cloud API calls with injected credentials, manages Results Store lifecycle, enforces role-based access control" "Node.js 26, Express 4, TypeScript"
        }

        gcs = softwareSystem "Google Cloud Storage" "Object storage for benchmark data and Results Store" "External"
        giq = softwareSystem "GKE Recommender API" "Inference performance profiles and GPU cost data" "External"
        githubAuth = softwareSystem "GitHub" "OAuth authentication and organization membership verification" "External"
        awsS3 = softwareSystem "AWS S3" "Public benchmark data from community contributors" "External"
        googleDrive = softwareSystem "Google Drive/Sheets" "Benchmark data from shared spreadsheets" "External"
        cloudRun = softwareSystem "Google Cloud Run" "Serverless container hosting with managed TLS and autoscaling" "External"

        llmdBenchmark = softwareSystem "llm-d-benchmark" "Benchmark runner that produces benchmark_report_v0.2 YAML files" "Internal llm-d"

        platformEngineer -> prism "Analyzes inference infrastructure options and costs"
        mlEngineer -> prism "Views benchmarks, submits results, reviews submissions"

        reactFrontend -> expressBFF "API requests via /api/* routes" "HTTP/8080"
        expressBFF -> gcs "Benchmark data retrieval, Results Store CRUD, IAM allowlists" "HTTPS/443, ADC Bearer"
        expressBFF -> giq "Inference performance profiles and cost data" "HTTPS/443, ADC Bearer"
        expressBFF -> githubAuth "OAuth code exchange, token refresh, user validation" "HTTPS/443"
        reactFrontend -> awsS3 "Public benchmark data (client-side)" "HTTPS/443"
        reactFrontend -> googleDrive "DRIVE-sourced benchmark data" "HTTPS/443"

        prism -> cloudRun "Deployed as container service" "HTTPS/443"

        llmdBenchmark -> gcs "Uploads benchmark_report_v0.2 YAML files" "HTTPS/443"
    }

    views {
        systemContext prism "SystemContext" {
            include *
            autoLayout
        }

        container prism "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal llm-d" {
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
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
