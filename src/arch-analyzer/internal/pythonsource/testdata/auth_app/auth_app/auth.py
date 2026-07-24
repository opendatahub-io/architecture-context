from auth_app.auth_providers import create_auth_provider


class AuthenticationMiddleware:
    def __init__(self, app, auth_config):
        self.app = app
        self.auth_provider = create_auth_provider(auth_config)

    async def __call__(self, scope, receive, send):
        if scope["type"] == "http":
            headers = dict(scope.get("headers", []))
            auth_header = headers.get(b"authorization", b"").decode()

            if not auth_header or not auth_header.startswith("Bearer "):
                return await self._send_auth_error(send, "Missing or invalid Authorization header")

            token = auth_header.split("Bearer ", 1)[1]

            try:
                result = await self.auth_provider.validate_token(token, scope)
            except Exception:
                return await self._send_auth_error(send, "Authentication failed")

            scope["principal"] = result.principal

        return await self.app(scope, receive, send)

    async def _send_auth_error(self, send, message):
        await send({"type": "http.response.start", "status": 401})
        await send({"type": "http.response.body", "body": message.encode()})
