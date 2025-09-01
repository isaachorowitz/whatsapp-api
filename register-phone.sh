#!/bin/bash

# WhatsApp Business API Phone Registration Script
# Load configuration
source config.env

echo "🚀 Starting WhatsApp Business API Phone Registration..."
echo "📱 Phone Number: +${COUNTRY_CODE}${PHONE_NUMBER}"
echo "🌐 API Endpoint: https://localhost:${WA_API_PORT}"

# Wait for API to be ready
echo "⏳ Waiting for API server to be ready..."
sleep 10

# Step 1: Login to get auth token
echo "🔐 Logging in to get authentication token..."
LOGIN_RESPONSE=$(curl -s -k -X POST https://localhost:${WA_API_PORT}/v1/users/login \
  -H "Content-Type: application/json" \
  -d "{
    \"username\": \"${ADMIN_USERNAME}\",
    \"password\": \"${ADMIN_PASSWORD}\"
  }")

echo "Login Response: $LOGIN_RESPONSE"

# Extract token (you'll need jq for this, or we'll do it manually)
TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo "❌ Failed to get authentication token"
    echo "Response: $LOGIN_RESPONSE"
    exit 1
fi

echo "✅ Got authentication token: ${TOKEN:0:20}..."

# Step 2: Register phone number
echo "📞 Registering phone number..."
REGISTER_RESPONSE=$(curl -s -k -X POST https://localhost:${WA_API_PORT}/v1/account \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"cc\": \"${COUNTRY_CODE}\",
    \"phone_number\": \"${PHONE_NUMBER#1}\",
    \"method\": \"sms\",
    \"cert\": \"${WA_CERT}\"
  }")

echo "Registration Response: $REGISTER_RESPONSE"

# Check response
if echo "$REGISTER_RESPONSE" | grep -q "201"; then
    echo "✅ Account already exists - registration complete!"
elif echo "$REGISTER_RESPONSE" | grep -q "202"; then
    echo "📨 Registration code sent via SMS!"
    echo "🔢 Check your phone for a 6-digit code, then run:"
    echo "   ./verify-code.sh YOUR_6_DIGIT_CODE"
else
    echo "❌ Registration failed"
    echo "Response: $REGISTER_RESPONSE"
fi
