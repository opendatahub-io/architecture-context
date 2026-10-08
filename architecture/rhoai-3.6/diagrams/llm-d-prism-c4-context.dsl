workspace {
    model {
        platformEngineer = person "AI Platform Engineer" "Chooses, configures, and optimizes AI inference infrastructure"
        mlEngineer = person "ML Engineer" "Analyzes benchmark results and submits new benchmark data"

        prism = softwareSystem "llm-d-prism" "Interactive performance analysis dashboard for distributed LLM inference systems" {
            expressBFF = container "Express BFF Server" "Backend API server proxying Google Cloud APIs, serving static assets, and managing the Results Store" "Node.js/TypeScript (Express)" "Backend"
            reactFrontend = container "React Frontend" "Interactive benchmark analysis dashboards with scatter charts, comparison views, and regression analysis" "React 19 / Vite / Recharts" "Frontend"
            resultsStore = container "Results Store" "CRUD API for benchmark result submissions with review and promotion workflow" "Express Router Module" "Backend"
            oauthModule = container "OAuth Module" "GitHub OAuth flow, token validation, and organization membership resolution" "Express Router Module" "Backend"
            iamModule = container "IAM Module" "Permission resolution via GCS-hosted allowlists and playground mode" "TypeScript Module" "Backend"
            arenaUpdater = container "Arena Score Updater" "Scrapes LMSYS Arena leaderboard for model quality scores" "Python Script" "Offline Tool"
        }

        gcs = softwareSystem "Google Cloud Storage" "Primary data store for benchmark results, regression reports, and IAM allowlists" "External"
        giq = softwareSystem "GKE Recommender API" "Infrastructure quality profiling and cost benchmarking data" "External"
        github = softwareSystem "GitHub" "User authentication via OAuth 2.0 and organization membership lookup" "External"
        arena = softwareSystem "LMSYS Arena" "Model quality leaderboard scores" "External"
        llmdBenchmark = softwareSystem "llm-d-benchmark" "Source of BRv0.2 YAML benchmark report files" "Internal llm-d"
        cloudRun = softwareSystem "Google Cloud Run" "Container hosting with managed TLS and autoscaling" "External"

        # User interactions
        platformEngineer -> prism "Analyzes infrastructure benchmarks and compares configurations"
        mlEngineer -> prism "Reviews benchmark results and submits new experiments"

        # Frontend-to-backend
        reactFrontend -> expressBFF "API calls via /api/* endpoints" "HTTP/8080"

        # Backend internal
        expressBFF -> resultsStore "Delegates results operations"
        resultsStore -> oauthModule "Validates user identity"
        resultsStore -> iamModule "Checks permissions"
        expressBFF -> iamModule "Checks permissions for GCS writes"

        # External integrations
        expressBFF -> gcs "Reads/writes benchmark data, regression reports" "HTTPS/443 Bearer ADC"
        resultsStore -> gcs "Stores and retrieves benchmark results" "HTTPS/443 Bearer ADC"
        iamModule -> gcs "Reads IAM allowlists" "HTTPS/443 Bearer ADC"
        expressBFF -> giq "Proxies infrastructure quality queries" "HTTPS/443 Bearer ADC"
        oauthModule -> github "OAuth token exchange and user/org lookup" "HTTPS/443 OAuth"
        arenaUpdater -> arena "Scrapes leaderboard HTML" "HTTPS/443 (no cert verify)"

        # Data format dependency
        expressBFF -> llmdBenchmark "Parses BRv0.2 YAML benchmark reports" "Data Format"

        # Hosting
        prism -> cloudRun "Deployed as Cloud Run service" "Container"
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
            element "Backend" {
                background #4a90e2
                color #ffffff
            }
            element "Frontend" {
                background #61dafb
                color #333333
            }
            element "Offline Tool" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}
