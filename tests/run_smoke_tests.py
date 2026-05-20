import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from fastapi.testclient import TestClient
from unittest.mock import patch

import app.workers.model_worker as model_worker
import app.workers.python_worker as python_worker

def test_model_worker():
    client = TestClient(model_worker.app)
    resp = client.post('/infer', json={'text': 'Hello'})
    print('model /infer ->', resp.status_code, resp.json())
    assert resp.status_code == 200
    assert 'response' in resp.json()


class FakeResp:
    def __init__(self, data):
        self._data = data
        self.status_code = 200
    def json(self):
        return self._data
    def raise_for_status(self):
        return None

def fake_requests_post(url, json=None, timeout=None):
    # Simulate TS worker rpc and Model worker infer responses
    if url.endswith('/rpc'):
        return FakeResp({'text': json['text'] + ' [from-ts]'})
    if url.endswith('/infer'):
        return FakeResp({'response': f"Hi there! (processed: {json['text']})"})
    raise RuntimeError(f'Unexpected URL: {url}')

def test_python_worker_with_patched_requests():
    with patch('requests.post', side_effect=fake_requests_post):
        client = TestClient(python_worker.app)
        resp = client.post('/rpc', json={'text': 'Hello'})
        print('python /rpc ->', resp.status_code, resp.json())
        assert resp.status_code == 200
        body = resp.json()
        assert 'response' in body


if __name__ == '__main__':
    test_model_worker()
    test_python_worker_with_patched_requests()
    print('SMOKE TESTS PASSED')
