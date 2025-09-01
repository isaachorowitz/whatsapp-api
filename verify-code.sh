#!/bin/bash

# WhatsApp Business API Phone Verification Script
if [ $# -eq 0 ]; then
    echo "Usage: ./verify-code.sh YOUR_6_DIGIT_CODE"
    exit 1
fi

CODE=$1
source config.env

echo "🔢 Verifying code: $CODE"

# Login to get token
LOGIN_RESPONSE=$(curl -s -k -X POST https://localhost:${WA_API_PORT}/v1/users/login \
  -H "Content-Type: application/json" \
  -d "{
    \"username\": \"${ADMIN_USERNAME}\",
    \"password\": \"${ADMIN_PASSWORD}\"
  }")

TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo "❌ Failed to get authentication token"
    exit 1
fi

# Verify code
VERIFY_RESPONSE=$(curl -s -k -X POST https://localhost:${WA_API_PORT}/v1/account/verify \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d "{
    \"code\": \"$CODE\"
  }")

echo "Verification Response: $VERIFY_RESPONSE"

if echo "$VERIFY_RESPONSE" | grep -q "success\|200"; then
    echo "✅ Phone number verified successfully!"
    echo "🎉 Your WhatsApp Business API is ready!"
    echo ""
    echo "📋 Connection Details:"
    echo "   API Endpoint: https://localhost:${WA_API_PORT}"
    echo "   Username: ${ADMIN_USERNAME}"
    echo "   Password: ${ADMIN_PASSWORD}"
    echo "   Phone: +${COUNTRY_CODE}${PHONE_NUMBER}"
else
    echo "❌ Verification failed"
    echo "Response: $VERIFY_RESPONSE"
fi
