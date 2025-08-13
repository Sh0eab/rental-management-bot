FROM rasa/rasa:3.6.0-full

# Switch to root user to install system dependencies
USER root

# Install system dependencies needed for mysql-connector-python
RUN apt-get update && apt-get install -y \
    python3-dev \
    default-libmysqlclient-dev \
    build-essential \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies as root user first
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir python-dotenv==1.0.0
RUN pip install --no-cache-dir requests
RUN pip install --no-cache-dir mysql-connector-python==8.0.33

# Switch back to rasa user
USER 1001

WORKDIR /app

# Copy the application code
COPY --chown=1001:1001 . .

# Train the model
RUN rasa train

# Expose port
EXPOSE 5005

# Create startup script that uses PORT environment variable
RUN echo '#!/bin/bash\nset -e\necho "Starting Rasa server..."\nPORT=${PORT:-5005}\necho "Using port: $PORT"\nexec rasa run --enable-api --cors "*" --port "$PORT" --host "0.0.0.0"' > /app/start.sh && chmod +x /app/start.sh

# Start the server
CMD ["/bin/bash", "/app/start.sh"]
