#!/bin/bash

# WhatsApp Cloud API Account Verification
source cloud-api-config.env

echo "🔍 Verifying WhatsApp Cloud API account..."
echo "📱 Phone Number ID: ${PHONE_NUMBER_ID}"
echo "🏢 WABA ID: ${WABA_ID}"

# Get phone number info
echo "📞 Getting phone number information..."
PHONE_INFO=$(curl -s -X GET \
  "${API_BASE_URL}/${PHONE_NUMBER_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

echo "Phone Info Response:"
echo "$PHONE_INFO"

# Get WABA info
echo ""
echo "🏢 Getting WhatsApp Business Account information..."
WABA_INFO=$(curl -s -X GET \
  "${API_BASE_URL}/${WABA_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

echo "WABA Info Response:"
echo "$WABA_INFO"

# Test if we can send a template message to ourselves (this will fail but shows if API works)
echo ""
echo "🧪 Testing API connectivity..."
TEST_RESPONSE=$(curl -s -i -X POST \
  "${API_BASE_URL}/${PHONE_NUMBER_ID}/messages" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"messaging_product\": \"whatsapp\",
    \"to\": \"${TEST_FROM_NUMBER}\",
    \"type\": \"template\",
    \"template\": {
      \"name\": \"hello_world\",
      \"language\": {
        \"code\": \"en_US\"
      }
    }
  }")

echo "API Test Response:"
echo "$TEST_RESPONSE"

if echo "$TEST_RESPONSE" | grep -q "200 OK"; then
    echo "✅ API is working correctly!"
elif echo "$TEST_RESPONSE" | grep -q "400"; then
    echo "⚠️ API is accessible but request had issues (normal for self-messaging)"
else
    echo "❌ API connection failed"
fi

echo ""
echo "🎯 Next steps:"
echo "1. Use ./send-message.sh +1234567890 to send messages"
echo "2. Your test number +15551923566 has 90 days of free messaging"
echo "3. To confirm your original number +15557936692, you'll need to verify it in Facebook Business Manager"
