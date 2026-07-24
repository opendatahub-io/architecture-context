use axum::{routing::{get, post}, Router};

pub fn health_router() -> Router {
    Router::new()
        .route("/health", get(health))
        .route("/info", get(info))
}

pub fn guardrails_router(enabled: bool) -> Router {
    let mut router = Router::new()
        .route(
            "/api/v1/detect",
            post(detect),
        );
    if enabled {
        router = router.route("/api/v1/optional", post(optional));
    }
    router
}

pub fn rewrite_forwarded_access_headers() {}

#[cfg(test)]
mod tests {
    fn test_router() {
        Router::new().route("/test-only", get(test));
    }
}

