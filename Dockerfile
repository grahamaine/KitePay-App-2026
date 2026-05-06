FROM ghcr.io/cirruslabs/flutter:stable

USER root
WORKDIR /app

# 1. Prepare the Local SDK (kitepay_sdk)
RUN mkdir -p kitepay_sdk
COPY kitepay_sdk/pubspec.yaml ./kitepay_sdk/
COPY kitepay_sdk/lib/ ./kitepay_sdk/lib/

# 2. Copy Main App Config
COPY pubspec.yaml pubspec.lock ./

# 3. Fetch Dependencies
# Standard command - just let it bark about being root
RUN flutter pub get

# 4. Copy the rest of the project
COPY . .

# 5. Pre-cache web artifacts
RUN flutter precache --web

# 6. Expose Web Port
EXPOSE 8080

CMD ["flutter", "run", "-d", "web-server", "--web-port", "8080", "--web-hostname", "0.0.0.0"]