FROM rasa/rasa:3.6.0-full

# Switch to root to install dependencies
USER root

# Install additional Python packages
RUN pip install --no-cache-dir \
    python-dotenv==1.0.0 \
    requests \
    mysql-connector-python==8.0.33 \
    rasa-sdk==3.6.0

# Switch to rasa user
USER 1001
WORKDIR /app

# Copy all files
COPY --chown=1001:1001 . .

# Train the model
RUN rasa train

# Set environment variable
ENV PORT=5005

# Expose port
EXPOSE 5005

# Simple command to start Rasa server only
CMD rasa run --enable-api --cors "*" --port $PORT --host 0.0.0.0
