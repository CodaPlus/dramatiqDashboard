# Use a builder image to install dependencies and build wheels
FROM python:3.10-slim as builder

# Create a user to run the app
RUN addgroup --system app && adduser --system --group app

# Set the working directory
WORKDIR /home/app

# Install system dependencies required for Python packages
RUN apt update -y && apt install -y \
    build-essential \
    libpq-dev && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN pip install poetry

# Copy only the files needed for installing Python dependencies
COPY pyproject.toml poetry.lock* ./

# Configure Poetry:
# - Do not create a virtual environment as the dependencies will be installed system-wide
# - Install only production dependencies
RUN poetry config virtualenvs.create false && \
    poetry install --no-dev

# Copy the rest of the application
COPY . .

# Change ownership of the app directory to the app user
RUN chown -R app:app /home/app

# Use the created user to run the app
USER app

# Set environment variables for Redis
ENV DRAMATIQ_REDIS_HOST=host.docker.internal
ENV DRAMATIQ_REDIS_PORT=6379

# Expose the port Gunicorn will listen on
EXPOSE 8400

# The final command to run the app using Gunicorn
CMD ["gunicorn", "-b", "0.0.0.0:8400", "app:app"]
