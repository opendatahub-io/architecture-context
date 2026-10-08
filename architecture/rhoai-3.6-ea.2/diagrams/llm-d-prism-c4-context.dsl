workspace {
    model {
        platformEngineer = person "AI Platform Engineer" "Chooses, configures, and optimizes inference infrastructure"
        mlEngineer = person "ML Engineer" "Runs benchmarks and analyzes inference performance"

        prism = softwareSystem "Prism" "Interactive performance-analysis dashboard for distributed AI inference systems" {
            expressBFF = container "Express BFF Server" "Proxies cloud API requests, manages Results Store, handles GitHub OAuth, serves SPA" "Node.js / TypeScript / Express"
            reactFrontend = container "React Frontend" "Interactive dashboard with scatter charts, regression analysis, P/D disaggregation views, and benchmark comparison" "React 19 / Vite / Recharts"
            resultsStore = container "Results Store" "Full CRUD lifecycle for benchmark submissions with Zod validation and state-machine workflow" "Express Router Module"
            oauthIAM = container "OAuth/IAM Module" "GitHub OAuth flow, org membership resolution, GCS-backed allowlist authorization" "Express Middleware"
        }

        gcs = softwareSystem "Google Cloud Storage" "Primary data backend: benchmark results, regression data, IAM allowlists, prefix-cache reports" "External"
        giq = softwareSystem "GKE Recommender API" "Inference quality and cost benchmarking profiles" "External"
        githubOAuth = softwareSystem "GitHub" "User authentication via OAuth and organization membership resolution" "External"
        s3 = softwareSystem "AWS S3" "Public benchmark data storage" "External"
        cloudRun = softwareSystem "Google Cloud Run" "Production deployment and scaling infrastructure" "External"

        platformEngineer -> prism "Analyzes inference benchmarks and configures infrastructure"
        mlEngineer -> prism "Submits benchmarks and views performance data"

        reactFrontend -> expressBFF "API calls" "HTTP/8080"
        expressBFF -> resultsStore "Routes /api/results requests"
        expressBFF -> oauthIAM "Authenticates and authorizes requests"
        resultsStore -> gcs "Stores/retrieves benchmark results" "HTTPS/443"
        oauthIAM -> githubOAuth "OAuth code exchange and user validation" "HTTPS/443"
        oauthIAM -> gcs "Fetches IAM allowlists" "HTTPS/443"
        expressBFF -> gcs "Proxies GCS operations and fetches regression/prefix-cache data" "HTTPS/443"
        expressBFF -> giq "Proxies inference quality API requests" "HTTPS/443"
        reactFrontend -> s3 "Reads public benchmark data" "HTTPS/443"
        prism -> cloudRun "Deployed on" "Container"
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
                background #357abd
                color #ffffff
            }
        }
    }
}
