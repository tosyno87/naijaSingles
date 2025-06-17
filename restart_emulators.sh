#!/bin/bash

echo "Stopping any running Firebase emulators..."
pkill -f "firebase emulators"

echo "Waiting for ports to be released..."
sleep 2

echo "Starting Firebase emulators with clean data..."
firebase emulators:start --import=./emulator-data --export-on-exit=./emulator-data

