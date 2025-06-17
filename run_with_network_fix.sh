#!/bin/bash

echo "Running NaijaSingles with network error handling..."

# Check if Firebase emulators are running
echo "Checking if Firebase emulators are running..."
if nc -z localhost 9099 2>/dev/null; then
  echo "Firebase Auth emulator is running on port 9099"
  EMULATORS_RUNNING=true
else
  echo "Firebase Auth emulator is NOT running on port 9099"
  EMULATORS_RUNNING=false
fi

if nc -z localhost 8080 2>/dev/null; then
  echo "Firebase Firestore emulator is running on port 8080"
  EMULATORS_RUNNING=true
else
  echo "Firebase Firestore emulator is NOT running on port 8080"
  EMULATORS_RUNNING=false
fi

# If emulators are not running, ask if user wants to start them
if [ "$EMULATORS_RUNNING" = false ]; then
  read -p "Do you want to start Firebase emulators? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Starting Firebase emulators..."
    firebase emulators:start --import=./emulator-data --export-on-exit=./emulator-data > emulator.log 2>&1 &
    EMULATOR_PID=$!
    
    # Wait for emulators to start
    echo "Waiting for emulators to initialize..."
    sleep 10
  else
    echo "Continuing without Firebase emulators. App will use production Firebase services."
  fi
fi

# Run Flutter with verbose logging
echo "Starting Flutter app..."
flutter run -v

# If we started emulators, kill them when Flutter exits
if [ -n "$EMULATOR_PID" ]; then
  kill $EMULATOR_PID || true
  echo "Emulators stopped."
fi

