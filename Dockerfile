# Use a builder image to install dependencies and build wheels
FROM python:3.10-slim as builder

WORKDIR /usr/src/app

# Create a non-root user
RUN addgroup --system app && adduser --system --group app

# Set environment variables
ENV HOME=/home/app
ENV APP_HOME=/home/app/web
WORKDIR $APP_HOME
ENV PYTHONPATH /home/app/web

EXPOSE 8800

# Install runtime dependencies (if any)
RUN apt-get update -qq && apt-get install -y --no-install-recommends libpq-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy the Python dependencies from the builder stage
COPY --from=builder /usr/src/app/wheels /wheels
COPY --from=builder /usr/src/app/requirements.txt .
RUN pip install --no-cache /wheels/*

# Copy the Django project into the container
COPY .env.prod .env
COPY . .

# Change ownership of the application files
RUN chown -R app:app $APP_HOME

# Switch to the non-root user
USER app