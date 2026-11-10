workspace "kube-auth-proxy" "RHOAI 3.7-ea.1 authentication reverse proxy / Envoy ext_authz backend" {
    model {
        user = person "Platform User" "Signs in to RHOAI web UIs with a browser"
        cliUser = person "CLI / SDK User" "Calls RHOAI APIs with a Kubernetes bearer token (oc whoami -t, ServiceAccount token)"

        kap = softwareSystem "kube-auth-proxy" "FIPS-built authentication reverse proxy forked from oauth2-proxy; OpenShift OAuth, OIDC and Kubernetes TokenReview authentication" {
            proxy = container "OAuthProxy" "Login, callback, sign-out, userinfo and /oauth2/auth endpoints; upstream proxy or static 200 for ext_authz" "Go, gorilla/mux + alice, 4180/TCP"
            oidcProvider = container "OIDC Provider" "Generic OIDC login with RP-initiated logout" "Go, coreos/go-oidc"
            ocpProvider = container "OpenShift Provider" "OAuth discovery, code redeem, users/~ lookup, ServiceAccount OAuth client" "Go"
            tokenReview = container "TokenReviewValidator" "Validates bearer tokens via TokenReview; singleflight dedup, 10s SHA-256-keyed cache, 30s timeout" "Go, client-go"
            sessionStore = container "Session Stores" "Encrypted cookie (AES-CFB + HMAC-SHA256) or Redis ticket (AES-GCM)" "Go"
            authDeny = container "authdeny MLflow Handler" "JSON 401 with login guidance for mlflow-python-client" "Go"
            metrics = container "Metrics Server" "Optional Prometheus /metrics endpoint" "Go, client_golang"
        }

        gateway = softwareSystem "data-science-gateway" "Gateway API / Envoy with ext_authz EnvoyFilter" "Internal RHOAI"
        operator = softwareSystem "rhods-operator" "Deploys kube-auth-proxy and gateway wiring" "Internal RHOAI"
        upstreamApp = softwareSystem "Upstream RHOAI Components" "Dashboard, workbenches, MLflow and other protected apps" "Internal RHOAI"
        kubeApi = softwareSystem "Kubernetes / OpenShift API" "TokenReview, users/~, OAuthAccessToken, OAuth discovery" "External"
        oauthServer = softwareSystem "OpenShift OAuth Server" "In-cluster OAuth2 authorization server" "External"
        idp = softwareSystem "External OIDC IdP" "Bring-your-own OIDC identity provider" "External"
        redis = softwareSystem "Redis / Valkey" "Optional shared session storage" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping" "External"

        user -> gateway "Accesses RHOAI" "HTTPS/443 TLS 1.2+"
        cliUser -> gateway "Calls APIs with Bearer token" "HTTPS/443 TLS 1.2+"
        user -> oauthServer "Authenticates" "HTTPS/443"
        user -> idp "Authenticates (BYOIDC)" "HTTPS/443"
        gateway -> proxy "ext_authz subrequest /oauth2/auth" "HTTP or HTTPS/4180"
        gateway -> upstreamApp "Forwards authenticated traffic with identity headers" "HTTPS"
        operator -> kap "Deploys"
        proxy -> upstreamApp "Proxies authenticated traffic (reverse-proxy mode)" "HTTP/HTTPS"
        proxy -> oidcProvider "Delegates OIDC login"
        proxy -> ocpProvider "Delegates OpenShift login"
        proxy -> tokenReview "Validates bearer tokens"
        proxy -> sessionStore "Loads/saves sessions"
        proxy -> authDeny "Builds denial responses"
        tokenReview -> kubeApi "Creates TokenReview" "HTTPS/443, SA token"
        ocpProvider -> kubeApi "OAuth discovery, users/~, OAuthAccessToken DELETE" "HTTPS/443"
        ocpProvider -> oauthServer "Redeems authorization code" "HTTPS/443"
        oidcProvider -> idp "Discovery, JWKS, token, end_session" "HTTPS/443"
        sessionStore -> redis "Stores session tickets" "TCP RESP, optional TLS"
        prometheus -> metrics "Scrapes" "HTTP/HTTPS"
    }

    views {
        systemContext kap "SystemContext" {
            include *
            autoLayout
        }

        container kap "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
