# syntax=docker/dockerfile:1
# Multi-stage build: install deps in a builder, copy into a slim runtime.
FROM python:3.12-slim AS builder
WORKDIR /app
COPY app/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-slim AS runtime
# Run as a non-root user (security scan + best practice).
RUN useradd --create-home --uid 10001 appuser
WORKDIR /app
COPY --from=builder /install /usr/local
COPY app/ /app/
ENV PORT=8080 APP_VERSION=dev
EXPOSE 8080
USER appuser
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://localhost:8080/healthz').status==200 else 1)"
# gunicorn for a production WSGI server (not the Flask dev server).
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "app:app"]
