FROM python:3.12-slim

WORKDIR /app

COPY pyproject.toml ./
RUN pip install --no-cache-dir hatchling && \
    pip install --no-cache-dir -e .

COPY specflow/ specflow/
COPY config/ config/

ENV PYTHONUNBUFFERED=1
ENV SERVICE=api

CMD if [ "$SERVICE" = "api" ]; then \
      exec uvicorn specflow.main:app --host 0.0.0.0 --port "${PORT:-8000}"; \
    elif [ "$SERVICE" = "worker" ]; then \
      exec python -m specflow.worker.main; \
    else \
      exec uvicorn specflow.mcp.main:app --host 0.0.0.0 --port "${PORT:-8001}"; \
    fi
