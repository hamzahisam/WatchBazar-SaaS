# ======================================================================================
# WatchBazar Dockerfile
# ======================================================================================
# This file tells Docker how to build a container image for your Django app.
# The container can run on Railway, Render, DigitalOcean, AWS, or any Docker host.
#
# HOW TO USE LOCALLY (optional):
# 1. Build: docker build -t watchbazar .
# 2. Run: docker run -p 8000:8000 --env-file .env watchbazar
# 3. Open: http://localhost:8000
#
# HOW RAILWAY/RENDER USE IT:
# They automatically detect this Dockerfile and build/deploy your app.
# ======================================================================================

# Use Python 3.12 slim image (smaller, faster)
ARG PYTHON_VERSION=3.12-slim-bullseye
FROM python:${PYTHON_VERSION}

# Create a virtual environment inside the container
RUN python -m venv /opt/venv

# Use the virtual environment
ENV PATH=/opt/venv/bin:$PATH

# Python settings for containers
# PYTHONDONTWRITEBYTECODE: Don't write .pyc files (keeps container smaller)
# PYTHONUNBUFFERED: Show print() output immediately (better for logging)
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Install system dependencies needed for PostgreSQL and image processing
RUN apt-get update && apt-get install -y \
    # For PostgreSQL (psycopg2)
    libpq-dev \
    # For Pillow (image processing, if you add it later)
    libjpeg-dev \
    # C compiler (needed for some Python packages)
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
RUN mkdir -p /code
WORKDIR /code

# Copy and install requirements first (Docker caches this layer)
COPY requirements.txt /tmp/requirements.txt
RUN pip install --upgrade pip
RUN pip install -r /tmp/requirements.txt

# Copy your Django project code
COPY . /code

# Collect static files (CSS, JS, images) for production
# Note: This runs at build time, not runtime
RUN python manage.py collectstatic --noinput

# Create startup script
# This script runs when the container starts:
# 1. Runs database migrations
# 2. Starts the production server (gunicorn)
RUN printf '#!/bin/bash\n\
RUN_PORT="${PORT:-8000}"\n\
echo "Running migrations..."\n\
python manage.py migrate --no-input\n\
echo "Starting server on port $RUN_PORT..."\n\
gunicorn config.wsgi:application --bind "0.0.0.0:$RUN_PORT"\n' > ./start.sh

# Make the script executable
RUN chmod +x start.sh

# Clean up to reduce image size
RUN apt-get remove --purge -y gcc \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Run the startup script when container starts
CMD ["./start.sh"]
