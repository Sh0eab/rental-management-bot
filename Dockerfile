FROM rasa/rasa:3.6.0-full

# Switch to root to install dependencies
USER root

# Install additional Python packages
RUN pip install --no-cache-dir \
    python-dotenv==1.0.0 \
    requests \
    mysql-connector-python==8.0.33 \
    rasa-sdk==3.6.0

# Create startup script that handles PORT properly
RUN echo '#!/bin/bash\nset -e\nPORT=${PORT:-10000}\necho "Starting Rasa on port: $PORT"\nexec rasa run --enable-api --cors "*" --port "$PORT" --host "0.0.0.0"' > /start.sh && \
    chmod +x /start.sh

# Switch to rasa user
USER 1001
WORKDIR /app

# Copy all files
COPY --chown=1001:1001 . .

# Train the model
RUN rasa train

# Override the ENTRYPOINT to use bash instead of rasa
ENTRYPOINT ["/bin/bash"]

# Run our startup script
CMD ["/start.sh"]
