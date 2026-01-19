FROM python:3.11-slim

WORKDIR /app

# Install eventlet for async support
RUN pip install --no-cache-dir eventlet gunicorn

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install additional dependencies
RUN pip install --no-cache-dir redis googletrans==4.0.0-rc1

# Force upgrade vulnerable packages to fix CVEs
RUN pip install --no-cache-dir --upgrade "h11>=0.16.0" "httpx>=0.23.0"

COPY . .

# Create non-root user
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 5000

# Use eventlet worker for WebSocket support
CMD ["gunicorn", "--worker-class", "eventlet", "-w", "1", "-b", "0.0.0.0:5000", "wsgi:app"]
