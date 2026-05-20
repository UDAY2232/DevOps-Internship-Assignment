"""
Python worker: receives RPC from API gateway, does lightweight processing,
then forwards to TypeScript worker, then returns aggregated result.
"""
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import os
import requests

app = FastAPI(title="Python Worker")

TS_WORKER_HOST = os.getenv("TS_WORKER_HOST", "10.10.0.12")
TS_WORKER_PORT = int(os.getenv("TS_WORKER_PORT", "9002"))
MODEL_WORKER_HOST = os.getenv("MODEL_WORKER_HOST", "10.10.0.13")
MODEL_WORKER_PORT = int(os.getenv("MODEL_WORKER_PORT", "9003"))


class RPCRequest(BaseModel):
    text: str


@app.post("/rpc")
def rpc(req: RPCRequest):
    if not req.text:
        raise HTTPException(status_code=400, detail="text is required")

    # Example processing: append a tag and forward to TS worker
    ts_payload = {"text": req.text + " [from-python]"}
    ts_url = f"http://{TS_WORKER_HOST}:{TS_WORKER_PORT}/rpc"
    try:
        r = requests.post(ts_url, json=ts_payload, timeout=10)
        r.raise_for_status()
        ts_resp = r.json()
    except requests.RequestException as e:
        raise HTTPException(status_code=502, detail=f"Failed to contact TS worker: {e}")

    # TS worker should return intermediate response; then forward to model worker
    model_payload = {"text": ts_resp.get("text", req.text)}
    model_url = f"http://{MODEL_WORKER_HOST}:{MODEL_WORKER_PORT}/infer"
    try:
        r2 = requests.post(model_url, json=model_payload, timeout=20)
        r2.raise_for_status()
        model_resp = r2.json()
    except requests.RequestException as e:
        raise HTTPException(status_code=502, detail=f"Failed to contact Model worker: {e}")

    # Return final inference
    return {"response": model_resp.get("response", ""), "text": model_payload["text"]}
