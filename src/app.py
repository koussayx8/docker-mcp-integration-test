#!/usr/bin/env python3
"""
Sample Python web application for Docker MCP and GitHub MCP integration testing.
"""

import os
import time
import json
import logging
from datetime import datetime
from flask import Flask, jsonify, render_template_string
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Create Flask app
app = Flask(__name__)

# Prometheus metrics
REQUEST_COUNT = Counter('app_requests_total', 'Total requests', ['method', 'endpoint'])
REQUEST_DURATION = Histogram('app_request_duration_seconds', 'Request duration')

# Application metrics
app_start_time = time.time()
request_count = 0

@app.before_request
def before_request():
    global request_count
    request_count += 1

@app.route('/')
def home():
    """Home page with application info."""
    REQUEST_COUNT.labels(method='GET', endpoint='/').inc()
    
    current_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    uptime = time.time() - app_start_time
    
    html_template = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Docker MCP Integration Test App</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; }
            .container { max-width: 800px; margin: 0 auto; }
            .status { padding: 20px; background: #f0f8ff; border-radius: 5px; }
            .metric { margin: 10px 0; }
            .success { color: #28a745; }
            .info { color: #17a2b8; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🐳 Docker MCP Integration Test App</h1>
            <div class="status">
                <h2>Application Status</h2>
                <div class="metric success">✅ Status: Running</div>
                <div class="metric info">🕐 Current Time: {{ current_time }}</div>
                <div class="metric info">⏱️ Uptime: {{ "%.2f"|format(uptime) }} seconds</div>
                <div class="metric info">📊 Total Requests: {{ request_count }}</div>
                <div class="metric info">🌿 Branch: {{ branch_name }}</div>
                <div class="metric info">🔧 Environment: {{ environment }}</div>
            </div>
            
            <h2>Available Endpoints</h2>
            <ul>
                <li><a href="/health">Health Check</a></li>
                <li><a href="/metrics">Prometheus Metrics</a></li>
                <li><a href="/api/info">API Info</a></li>
                <li><a href="/api/test">API Test</a></li>
            </ul>
            
            <h2>Integration Features</h2>
            <ul>
                <li>🐳 Docker containerization with health checks</li>
                <li>📊 Prometheus metrics collection</li>
                <li>🔧 Multi-stage Docker build</li>
                <li>🌐 Nginx reverse proxy support</li>
                <li>📈 Performance monitoring</li>
                <li>🔄 GitHub MCP integration ready</li>
            </ul>
        </div>
    </body>
    </html>
    """
    
    return render_template_string(
        html_template,
        current_time=current_time,
        uptime=uptime,
        request_count=request_count,
        branch_name=os.getenv('BRANCH_NAME', 'main'),
        environment=os.getenv('APP_ENV', 'development')
    )

@app.route('/health')
def health():
    """Health check endpoint."""
    REQUEST_COUNT.labels(method='GET', endpoint='/health').inc()
    
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'uptime': time.time() - app_start_time,
        'version': '1.0.0'
    })

@app.route('/metrics')
def metrics():
    """Prometheus metrics endpoint."""
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.route('/api/info')
def api_info():
    """API information endpoint."""
    REQUEST_COUNT.labels(method='GET', endpoint='/api/info').inc()
    
    return jsonify({
        'app_name': 'Docker MCP Integration Test',
        'version': '1.0.0',
        'branch': os.getenv('BRANCH_NAME', 'main'),
        'environment': os.getenv('APP_ENV', 'development'),
        'container_id': os.getenv('HOSTNAME', 'unknown'),
        'python_version': os.sys.version,
        'start_time': app_start_time,
        'current_time': time.time()
    })

@app.route('/api/test')
def api_test():
    """API test endpoint for integration testing."""
    REQUEST_COUNT.labels(method='GET', endpoint='/api/test').inc()
    
    # Simulate some processing
    time.sleep(0.1)
    
    return jsonify({
        'test': 'success',
        'message': 'API is working correctly',
        'timestamp': datetime.now().isoformat(),
        'random_number': int(time.time() * 1000) % 1000
    })

@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors."""
    return jsonify({'error': 'Not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors."""
    logger.error(f"Internal error: {error}")
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8000))
    debug = os.getenv('APP_ENV', 'development') == 'development'
    
    logger.info(f"Starting application on port {port}")
    logger.info(f"Environment: {os.getenv('APP_ENV', 'development')}")
    logger.info(f"Branch: {os.getenv('BRANCH_NAME', 'main')}")
    
    app.run(host='0.0.0.0', port=port, debug=debug)
