import os

import httpx
import uvicorn
from fastapi import APIRouter

router = APIRouter(prefix="/v1")


@router.get("/widgets")
async def list_widgets():
    return httpx.get("https://models.example.com/v1/widgets")


@router.post("/widgets")
async def create_widget():
    return {"token": os.getenv("WIDGET_API_TOKEN")}


uvicorn.run("widget_api.app:router", port=8000)
