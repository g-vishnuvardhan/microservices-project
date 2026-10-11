FROM python:3.11-slim AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt
FROM python:3.11-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PORT=5002
WORKDIR /app
COPY --from=builder /wheels /wheels
COPY requirements.txt .
RUN pip install --no-cache-dir --no-index --find-links=/wheels -r requirements.txt && rm -rf /wheels && useradd --create-home --uid 10001 appuser
COPY --chown=appuser:appuser . .
USER 10001
EXPOSE 5002
HEALTHCHECK --interval=15s --timeout=5s --start-period=20s --retries=5 CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:5002/readyz',timeout=3)"
CMD ["gunicorn", "--bind", "0.0.0.0:5002", "--workers", "2", "--threads", "2", "--timeout", "30", "app:app"]
