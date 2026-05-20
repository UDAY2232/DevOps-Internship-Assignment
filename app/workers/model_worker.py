"""
Model worker: runs inference locally (dummy model for quickstart). Exposes internal-only RPC.
"""
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import os
import time

app = FastAPI(title="Model Worker")


class ModelRequest(BaseModel):
    text: str


@app.post("/infer")
def infer(req: ModelRequest):
    if not req.text:
        raise HTTPException(status_code=400, detail="text is required")

    # Dummy inference logic - replace with actual model invocation in prod.
    # Simulate some processing latency.
    time.sleep(0.2)
    result = f"Hi there! (processed: {req.text})"
    return {"response": result}
