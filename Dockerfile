FROM rasa/rasa:3.6.0-full

# Switch to root to install dependencies
USER root

# Install additional Python packages
RUN pip install --no-cache-dir \
    python-dotenv==1.0.0 \
    requests \
    mysql-connector-python==8.0.33 \
    rasa-sdk==3.6.0

# Create comprehensive startup script with better error handling
RUN echo '#!/bin/bash\n\
set -e\n\
echo "=== Rasa Startup Script ==="\n\
echo "Environment variables:"\n\
echo "PORT=${PORT:-10000}"\n\
echo "PWD=$(pwd)"\n\
echo "USER=$(whoami)"\n\
\n\
echo "Checking files..."\n\
ls -la\n\
\n\
echo "Checking models directory..."\n\
if [ -d "models" ]; then\n\
  echo "Models directory exists:"\n\
  ls -la models/\n\
else\n\
  echo "Models directory not found!"\n\
  exit 1\n\
fi\n\
\n\
echo "Testing rasa installation..."\n\
rasa --version\n\
\n\
PORT=${PORT:-10000}\n\
echo "Starting Rasa server on port: $PORT"\n\
echo "Command: rasa run --enable-api --cors \"*\" --port \"$PORT\" --host \"0.0.0.0\""\n\
exec rasa run --enable-api --cors "*" --port "$PORT" --host "0.0.0.0"' > /start.sh && \
    chmod +x /start.sh

# Switch to rasa user
USER 1001
WORKDIR /app

# Copy all files
COPY --chown=1001:1001 . .

# Train the model and verify it exists
RUN rasa train && \
    echo "Model training completed. Checking models:" && \
    ls -la models/ && \
    echo "Training successful!"

# Override the ENTRYPOINT to use bash instead of rasa
ENTRYPOINT ["/bin/bash"]

# Run our startup script
CMD ["/start.sh"]
