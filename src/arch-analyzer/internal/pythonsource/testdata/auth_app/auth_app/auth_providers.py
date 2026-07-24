from abc import ABC, abstractmethod

import httpx
from jose import jwt


class AuthProvider(ABC):
    @abstractmethod
    async def validate_token(self, token, scope=None):
        pass

    @abstractmethod
    async def close(self):
        pass


class JWTAuthProvider(AuthProvider):
    def __init__(self, config):
        self.config = config
        self._jwks = {}

    async def validate_token(self, token, scope=None):
        await self._refresh_jwks()
        header = jwt.get_unverified_header(token)
        kid = header["kid"]
        key_data = self._jwks[kid]
        claims = jwt.decode(token, key_data, audience=self.config.audience)
        return User(principal=claims["sub"])

    async def _refresh_jwks(self):
        async with httpx.AsyncClient() as client:
            res = await client.get(self.config.jwks.uri)
            self._jwks = {k["kid"]: k for k in res.json()["keys"]}

    async def close(self):
        pass


class ExternalAuthProvider(AuthProvider):
    def __init__(self, config):
        self.config = config

    async def validate_token(self, token, scope=None):
        async with httpx.AsyncClient() as client:
            response = await client.post(self.config.endpoint, json={"api_key": token})
            if response.status_code != 200:
                raise ValueError("Authentication failed")
            data = response.json()
            return User(principal=data["principal"])

    async def close(self):
        pass


def create_auth_provider(config):
    provider_type = config.provider_type.lower()
    if provider_type == "jwt":
        return JWTAuthProvider(config.config)
    elif provider_type == "external":
        return ExternalAuthProvider(config.config)
    else:
        raise ValueError(f"Unsupported provider: {provider_type}")
