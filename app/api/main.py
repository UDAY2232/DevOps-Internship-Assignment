"""
FastAPI API gateway that validates requests, dispatches RPC calls to private workers,
and returns the final inference result as JSON.
"""
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import os
import httpx

app = FastAPI(title="DevOps Assignment API Gateway")

PYTHON_WORKER_HOST = os.getenv("PYTHON_WORKER_HOST", "10.10.0.11")
PYTHON_WORKER_PORT = int(os.getenv("PYTHON_WORKER_PORT", "9001"))


class InferRequest(BaseModel):
    text: str


class InferResponse(BaseModel):
    response: str


@app.post("/infer", response_model=InferResponse)
async def infer(req: InferRequest):
    # Validate input
    if not req.text or not req.text.strip():
        raise HTTPException(status_code=400, detail="text must be a non-empty string")

    # Call Python worker over private RPC (HTTP JSON) - synchronous chain
    python_url = f"http://{PYTHON_WORKER_HOST}:{PYTHON_WORKER_PORT}/rpc"
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            r = await client.post(python_url, json={"text": req.text})
            r.raise_for_status()
            payload = r.json()
    except httpx.RequestError as e:
        raise HTTPException(status_code=502, detail=f"Failed to contact python worker: {e}")
    except httpx.HTTPStatusError as e:
        raise HTTPException(status_code=502, detail=f"Python worker error: {e.response.text}")

    # Expect payload to contain final response from model chain
    if "response" not in payload:
        raise HTTPException(status_code=502, detail="Invalid response from workers")

    return {"response": payload["response"]}
