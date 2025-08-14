# Use Python slim image instead of heavy Rasa image
FROM python:3.9-slim

# Install minimal system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Install only essential Python packages
RUN pip install --no-cache-dir \
    rasa==3.6.0 \
    python-dotenv==1.0.0 \
    requests

# Create non-root user
RUN useradd --create-home --shell /bin/bash rasa
USER rasa
WORKDIR /app

# Copy only necessary files
COPY --chown=rasa:rasa config.yml domain.yml endpoints.yml ./
COPY --chown=rasa:rasa data/ data/

# Train model (this creates the models/ directory)
RUN rasa train

# Start command
CMD rasa run --enable-api --cors "*" --port ${PORT:-8080} --host 0.0.0.0
