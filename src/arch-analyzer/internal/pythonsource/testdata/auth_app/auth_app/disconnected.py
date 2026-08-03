"""Disconnected auth class - never registered as middleware, never used by factory."""


class UnusedAuthProvider:
    async def validate_token(self, token, scope=None):
        import jwt
        claims = jwt.decode(token, "secret", algorithms=["HS256"])
        return {"principal": claims["sub"]}

    async def close(self):
        pass
