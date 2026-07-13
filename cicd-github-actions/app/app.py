"""Tiny Flask app — the payload the CI/CD pipeline builds, tests, and ships."""
import os

from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/")
def index():
    return jsonify(
        service="portfolio-app",
        version=os.environ.get("APP_VERSION", "dev"),
        message="Deployed via GitHub Actions CI/CD.",
    )


@app.get("/healthz")
def healthz():
    """Liveness/readiness probe target used by the Kubernetes Deployment."""
    return jsonify(status="ok"), 200


if __name__ == "__main__":
    # Local/dev entrypoint only — the container runs gunicorn (see Dockerfile CMD).
    # Binding all interfaces is intentional for containerised use. nosec B104.
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8080")))  # nosec B104
