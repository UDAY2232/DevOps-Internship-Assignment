FROM python:3.10-slim
WORKDIR /opt/worker

RUN apt-get update && apt-get install -y build-essential && rm -rf /var/lib/apt/lists/*

COPY app/workers/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY app/workers /opt/worker

EXPOSE 9001

CMD ["uvicorn", "python_worker:app", "--host", "0.0.0.0", "--port", "9001"]
