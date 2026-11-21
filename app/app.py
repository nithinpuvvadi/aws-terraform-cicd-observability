from flask import Flask, jsonify, Response, request
from prometheus_client import (
    Counter,
    Histogram,
    generate_latest,
    CONTENT_TYPE_LATEST
)
import time

app = Flask(__name__)

REQUEST_COUNT = Counter(
    "app_requests_total",
    "Total application requests",
    ["method", "endpoint", "status"]
)

REQUEST_LATENCY = Histogram(
    "app_request_latency_seconds",
    "Application request latency"
)

@app.before_request
def start_timer():
    request.start_time = time.time()

@app.after_request
def record_metrics(response):
    latency = time.time() - request.start_time

    if request.path != "/metrics":
        REQUEST_COUNT.labels(
            request.method,
            request.path,
            response.status_code
        ).inc()

        REQUEST_LATENCY.observe(latency)

    return response

@app.route("/")
def home():
    return jsonify({
        "application": "AWS DevOps Demo",
        "status": "running",
        "version": "1.0"
    })

@app.route("/health")
def health():
    return jsonify({"status": "healthy"}), 200

@app.route("/api")
def api():
    return jsonify({"message": "Hello from AWS DevOps Project"})

@app.route("/metrics")
def metrics():
    return Response(
        generate_latest(),
        mimetype=CONTENT_TYPE_LATEST
    )

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
