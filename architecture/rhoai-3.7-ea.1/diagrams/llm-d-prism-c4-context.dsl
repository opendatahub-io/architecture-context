workspace "llm-d-prism" "Benchmark dashboard and Results Store for llm-d inference benchmarks" {
    model {
        engineer = person "AI Platform / ML Engineer" "Compares inference-serving configurations across llm-d well-lit paths"
        contributor = person "Benchmark Contributor" "Submits BRv0.2 benchmark runs"
        admin = person "Results Store Admin" "Reviews and promotes submitted runs"
        agent = softwareSystem "AI Coding Agent" "Uses prism-results CLI and SKILL.md to submit results" "Client"

        prism = softwareSystem "llm-d Prism" "Benchmark dashboard (React SPA) plus Express BFF and Results Store, hosted on Google Cloud Run at prism.llm-d.ai" {
            spa = container "Prism SPA" "Dashboards: P/D disaggregation, prefix-cache, intelligent routing, regressions, agentic workloads" "React 19, Vite, Tailwind, Recharts"
            server = container "Prism Server" "Serves SPA, GIQ and GCS proxies, local-file and dashboard data APIs, runtime config injection" "Node.js 26, Express, tsx; 8080/TCP"
            oauth = container "OAuth Router" "GitHub OAuth login/callback/refresh; validates tokens and resolves permission level" "Express router"
            iam = container "IAM Module" "Reads GCS allowlists; Playground Mode switch" "TypeScript library"
            results = container "Results Store" "Submit, list, get, export, promote, review, delete benchmark runs; serves agent tooling" "Express router + GCS"
            cli = container "prism-results CLI" "Standalone CLI for submitting results, downloadable from /api/results/agent/prism.mjs" "Node.js (esbuild bundle)"
        }

        cloudRun = softwareSystem "Google Cloud Run" "Hosting, TLS termination, autoscaling (0-100 instances)" "External"
        gcs = softwareSystem "Google Cloud Storage" "Bucket llm-d-benchmarks: Results Store, prism-iam allowlists, benchmark data" "External"
        giq = softwareSystem "GKE Inference Quickstart API" "gkerecommender.googleapis.com: benchmark profiles and cost data" "External"
        github = softwareSystem "GitHub OAuth + REST API" "Identity and llm-d org membership" "External"
        clientSources = softwareSystem "Browser-side sources" "S3, Google Drive picker, Google Analytics" "External"
        harness = softwareSystem "llm-d benchmark harnesses" "llm-d-benchmark / inference-perf producing BRv0.2 reports" "Internal llm-d"

        engineer -> spa "Views dashboards" "HTTPS/443"
        contributor -> spa "Submits runs via UI" "HTTPS/443"
        admin -> spa "Reviews and promotes runs" "HTTPS/443"
        contributor -> cli "Runs"
        agent -> cli "Downloads and runs"
        cli -> results "POST /api/results with X-Prism-Github-Token" "HTTPS/443"
        spa -> server "API calls (/api/*)" "HTTPS/443 via Cloud Run edge"
        spa -> clientSources "Loads client-side data and analytics" "HTTPS/443"
        server -> oauth "Routes /api/auth/github/*"
        server -> results "Routes /api/results*"
        oauth -> iam "Merges allowlist role"
        results -> iam "Checks permission"
        oauth -> github "Token exchange, /user, org membership" "HTTPS/443"
        iam -> gcs "Reads prism-iam allowlists (ADC)" "HTTPS/443"
        results -> gcs "Reads/writes runs under results-store prefix (ADC)" "HTTPS/443"
        server -> gcs "Bucket proxy /api/gcs/* (ADC)" "HTTPS/443"
        server -> giq "Proxy /api/giq/* (user Bearer or server ADC)" "HTTPS/443"
        cloudRun -> server "Terminates TLS, forwards" "HTTP/8080"
        harness -> gcs "Publishes BRv0.2 benchmark reports"
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
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal llm-d" {
                background #7ed321
            }
            element "Client" {
                background #f5a623
            }
        }
    }
}
