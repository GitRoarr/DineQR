#!/bin/bash

# Flutter Docker Helper Script
# Run Flutter commands without installing Flutter SDK locally

FLUTTER_IMAGE="cirrusci/flutter:stable"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)/frontend"

run_flutter() {
    docker run --rm -it \
        -v "$PROJECT_DIR:/app" \
        -w /app \
        $FLUTTER_IMAGE \
        flutter "$@"
}

case "$1" in
    pub)
        shift
        run_flutter pub "$@"
        ;;
    build)
        shift
        run_flutter build "$@"
        ;;
    run)
        shift
        run_flutter run "$@"
        ;;
    analyze)
        run_flutter analyze
        ;;
    test)
        shift
        run_flutter test "$@"
        ;;
    clean)
        run_flutter clean
        ;;
    doctor)
        run_flutter doctor
        ;;
    *)
        echo "Flutter Docker Helper"
        echo ""
        echo "Usage: $0 <command> [args]"
        echo ""
        echo "Commands:"
        echo "  pub get          - Get dependencies"
        echo "  pub upgrade      - Upgrade dependencies"
        echo "  build web        - Build for web"
        echo "  build apk        - Build Android APK"
        echo "  run              - Run the app"
        echo "  analyze          - Analyze code"
        echo "  test             - Run tests"
        echo "  clean            - Clean build files"
        echo "  doctor           - Check Flutter installation"
        echo ""
        echo "Examples:"
        echo "  $0 pub get"
        echo "  $0 build web"
        echo "  $0 run -d chrome"
        ;;
esac
