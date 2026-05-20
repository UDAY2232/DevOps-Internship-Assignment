FROM python:3.10-slim

WORKDIR /opt/app

# Install system deps
RUN apt-get update && apt-get install -y build-essential && rm -rf /var/lib/apt/lists/*

COPY app/api/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY app/api /opt/app

EXPOSE 8080

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
