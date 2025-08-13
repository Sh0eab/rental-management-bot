FROM rasa/rasa:3.6.0-full

WORKDIR /app

# Install additional dependencies
RUN pip install mysql-connector-python python-dotenv

# Copy the application code
COPY . .

# Train the model
RUN rasa train

# Expose port
EXPOSE 5005

# Start the server
CMD ["rasa", "run", "--enable-api", "--cors", "*", "--port", "5005"]