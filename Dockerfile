FROM rasa/rasa:3.6.0-full

# Switch to root user to install dependencies
USER root

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3-dev \
    default-libmysqlclient-dev \
    build-essential \
    pkg-config \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    python-dotenv==1.0.0 \
    requests \
    mysql-connector-python==8.0.33 \
    rasa-sdk==3.6.0

# Create supervisord configuration for managing both services
RUN echo '[supervisord]\n\
nodaemon=true\n\
user=root\n\
logfile=/tmp/supervisord.log\n\
pidfile=/tmp/supervisord.pid\n\
\n\
[program:rasa-actions]\n\
command=rasa run actions --port 5055 --host 0.0.0.0\n\
directory=/app\n\
user=1001\n\
autostart=true\n\
autorestart=true\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0\n\
\n\
[program:rasa-server]\n\
command=rasa run --enable-api --cors "*" --port %(ENV_PORT)s --host 0.0.0.0\n\
directory=/app\n\
user=1001\n\
autostart=true\n\
autorestart=true\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0' > /etc/supervisor/conf.d/rasa.conf

# Switch to rasa user and set working directory
USER 1001
WORKDIR /app

# Copy application files
COPY --chown=1001:1001 . .

# Train the model
RUN rasa train

# Switch back to root to run supervisor
USER root

# Set default PORT if not provided
ENV PORT=5005

# Expose port for Render
EXPOSE 5005

# Use supervisord to manage both services
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
