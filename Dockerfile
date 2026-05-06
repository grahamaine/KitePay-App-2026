# Use the official Flutter image
FROM ghcr.io/cirruslabs/flutter:stable

# Set workspace
WORKDIR /app

# Step 1: Copy only pubspec to cache the 'pub get' layer
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Step 2: Copy the rest of the code
COPY . .

# Step 3: Ensure the web SDK is downloaded
RUN flutter precache --web

# Expose the port Flutter will serve on
EXPOSE 8080

# Run as web-server
CMD ["flutter", "run", "-d", "web-server", "--web-port", "8080", "--web-hostname", "0.0.0.0"]