FROM rasa/rasa:3.6.0-full

# Switch to root for installations
USER root

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3-dev \
    default-libmysqlclient-dev \
    build-essential \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip install --no-cache-dir \
    python-dotenv==1.0.0 \
    requests \
    mysql-connector-python==8.0.33 \
    rasa-sdk==3.6.0

# Switch to rasa user
USER 1001
WORKDIR /app

# Copy application files
COPY --chown=1001:1001 . .

# Train the model
RUN rasa train

# Railway automatically provides PORT environment variable
# Simple startup command - no complex scripts needed
CMD rasa run --enable-api --cors "*" --port ${PORT:-8080} --host 0.0.0.0
