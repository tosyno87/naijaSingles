#!/bin/bash

echo "Running NaijaSingles in debug mode with verbose logging..."

# Kill any running emulators
pkill -f "firebase emulators" || true

# Wait for ports to be released
sleep 2

# Start Firebase emulators in the background
echo "Starting Firebase emulators..."
firebase emulators:start --import=./emulator-data --export-on-exit=./emulator-data > emulator.log 2>&1 &
EMULATOR_PID=$!

# Wait for emulators to start
echo "Waiting for emulators to initialize..."
sleep 10

# Run Flutter with verbose logging
echo "Starting Flutter app..."
flutter run -v

# When Flutter exits, kill the emulators
kill $EMULATOR_PID || true
echo "Emulators stopped."

