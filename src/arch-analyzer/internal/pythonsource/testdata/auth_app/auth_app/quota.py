import time


class QuotaMiddleware:
    """Rate limiting middleware - not an authentication mechanism."""

    def __init__(self, app, max_requests=100):
        self.app = app
        self.max_requests = max_requests
        self.counts = {}

    async def __call__(self, scope, receive, send):
        if scope["type"] == "http":
            auth_id = scope.get("authenticated_client_id")
            if auth_id:
                key = auth_id
            else:
                client = scope.get("client")
                key = client[0] if client else "anonymous"

            count = self.counts.get(key, 0) + 1
            self.counts[key] = count
            if count > self.max_requests:
                await send({"type": "http.response.start", "status": 429})
                await send({"type": "http.response.body", "body": b"Rate limited"})
                return

        return await self.app(scope, receive, send)
