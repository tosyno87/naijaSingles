#!/bin/bash

echo "Stopping any running Firebase emulators..."
pkill -f firebase

echo "Starting Firebase emulators..."
firebase emulators:start --only auth,firestore,storage
