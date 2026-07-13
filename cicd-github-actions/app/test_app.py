"""Unit tests exercised by the CI pipeline's test stage."""
from app import app


def client():
    app.config.update(TESTING=True)
    return app.test_client()


def test_index_ok():
    resp = client().get("/")
    assert resp.status_code == 200
    body = resp.get_json()
    assert body["service"] == "portfolio-app"
    assert "message" in body


def test_healthz_ok():
    resp = client().get("/healthz")
    assert resp.status_code == 200
    assert resp.get_json()["status"] == "ok"
