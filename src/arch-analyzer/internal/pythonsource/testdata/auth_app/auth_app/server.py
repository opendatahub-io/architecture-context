import uvicorn
from fastapi import FastAPI

from auth_app.auth import AuthenticationMiddleware
from auth_app.quota import QuotaMiddleware

app = FastAPI()

if config.server.auth:
    app.add_middleware(AuthenticationMiddleware, auth_config=config.server.auth)

if config.server.quota:
    app.add_middleware(QuotaMiddleware, max_requests=100)


@app.get("/v1/health")
async def health():
    return {"status": "ok"}


uvicorn.run("auth_app.server:app", port=8080)
