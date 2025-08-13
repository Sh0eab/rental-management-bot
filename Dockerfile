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

# Make startup script executable
RUN chmod +x start.sh

# Train the model
RUN rasa train

# Expose port
EXPOSE 5005

# Start the server
CMD ["./start.sh"]
