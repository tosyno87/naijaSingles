#!/bin/bash
echo "Creating test user in Firebase Auth Emulator..."
curl -X POST http://localhost:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key \
  -H 'Content-Type: application/json' \
  --data-binary '{"email":"test@example.com","password":"password123","returnSecureToken":true}'

echo -e "\n\nCreating test phone user..."
curl -X POST http://localhost:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPhoneNumber?key=fake-api-key \
  -H 'Content-Type: application/json' \
  --data-binary '{"phoneNumber":"+12179044453","code":"123456"}'
