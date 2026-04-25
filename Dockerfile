# Use the official Flutter image
FROM ghcr.io/cirruslabs/flutter:stable

# Set workspace
WORKDIR /app

# Copy files and get dependencies
COPY . .
RUN flutter pub get

# Default command to run for web development
CMD ["flutter", "run", "-d", "web-server", "--web-port", "8080", "--web-hostname", "0.0.0.0"]