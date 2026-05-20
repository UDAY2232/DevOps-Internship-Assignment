FROM python:3.10-slim
WORKDIR /opt/model

RUN apt-get update && apt-get install -y build-essential && rm -rf /var/lib/apt/lists/*

COPY app/workers/model-requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY app/workers /opt/model

EXPOSE 9003

CMD ["uvicorn", "model_worker:app", "--host", "0.0.0.0", "--port", "9003"]
