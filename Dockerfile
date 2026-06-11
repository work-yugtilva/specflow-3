FROM python:3.12-slim

WORKDIR /app

COPY specflow/pyproject.toml specflow/
RUN pip install --no-cache-dir hatchling && \
    pip install --no-cache-dir -e specflow/

COPY specflow/ specflow/
COPY config/ config/

ENV PYTHONUNBUFFERED=1

# Three start commands, one image:
# api:    uvicorn specflow.main:app --host 0.0.0.0 --port 8000
# worker: python -m specflow.worker.main
# mcp:    uvicorn specflow.mcp.main:app --host 0.0.0.0 --port 8001
CMD ["uvicorn", "specflow.main:app", "--host", "0.0.0.0", "--port", "8000"]
