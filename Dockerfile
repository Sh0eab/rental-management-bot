FROM rasa/rasa:3.6.0-full

# Switch to root user to install dependencies
USER root

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3-dev \
    default-libmysqlclient-dev \
    build-essential \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    python-dotenv==1.0.0 \
    requests \
    mysql-connector-python==8.0.33 \
    rasa-sdk==3.6.0

# Switch to rasa user and set working directory
USER 1001
WORKDIR /app

# Copy application files
COPY --chown=1001:1001 . .

# Train the model
RUN rasa train

# Create startup script as rasa user
USER root
RUN echo '#!/bin/bash\nset -e\necho "Starting Rasa Bot on Render..."\nPORT=${PORT:-5005}\necho "Port: $PORT"\n\n# Start action server in background\necho "Starting action server..."\nsu - 1001 -c "cd /app && rasa run actions --port 5055 --host 0.0.0.0" &\nACTION_PID=$!\necho "Action server PID: $ACTION_PID"\n\n# Wait for action server\nsleep 8\n\n# Start Rasa server\necho "Starting Rasa server..."\nsu - 1001 -c "cd /app && rasa run --enable-api --cors \"*\" --port $PORT --host 0.0.0.0"' > /app/start.sh && \
    chmod +x /app/start.sh

# Expose port for Render
EXPOSE 5005

# Run startup script
CMD ["/app/start.sh"]
