# Use a slim and secure Python base image
FROM python:3.9-slim-buster

# Avoid writing .pyc files, and allow logging to stdout
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set working directory
WORKDIR /app

# Install system-level dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
 && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the source code
COPY . .

# Healthcheck (optional but recommended)
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
 CMD curl --fail http://localhost:8080/health || exit 1

# Expose port (for documentation)
EXPOSE 8080

# Run your Flask app
CMD ["python", "app.py"]
