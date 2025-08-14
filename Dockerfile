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

# Render provides PORT via environment variable
# Default to 10000 if not provided (Render's default)
ENV PORT=10000

# Expose the port
EXPOSE $PORT

# Use exec form and proper port variable substitution
CMD ["sh", "-c", "rasa run --enable-api --cors '*' --port ${PORT} --host 0.0.0.0"]
