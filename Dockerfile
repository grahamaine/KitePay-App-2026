FROM ghcr.io/cirruslabs/flutter:stable

# Use root for the setup phase
USER root
WORKDIR /app

# 1. Pre-create the directory structure
RUN mkdir -p kitepay_sdk

# 2. Copy the SDK's pubspec and source first
# This allows the main app to 'link' to it during resolution
COPY kitepay_sdk/pubspec.yaml ./kitepay_sdk/
COPY kitepay_sdk/lib/ ./kitepay_sdk/lib/

# 3. Copy the main app's pubspec
COPY pubspec.yaml pubspec.lock ./

# 4. Fix permissions so the 'flutter' user can access these files
RUN chown -R flutter:flutter /app

# 5. Switch to the flutter user to avoid the 'root' warning
USER flutter

# 6. Fetch dependencies
RUN flutter pub get

# 7. Copy the rest of the code
COPY --chown=flutter:flutter . .

EXPOSE 8080

CMD ["flutter", "run", "-d", "web-server", "--web-port", "8080", "--web-hostname", "0.0.0.0"]