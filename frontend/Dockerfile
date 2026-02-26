FROM cirrusci/flutter:stable

WORKDIR /app

# Copy pubspec files first for better caching
COPY pubspec.yaml pubspec.lock* ./

# Get dependencies
RUN flutter pub get

# Copy the rest of the app
COPY . .

# Build for web (default)
CMD ["flutter", "build", "web"]
