#!/bin/bash

# WhatsApp Cloud API Message Sender
source cloud-api-config.env

if [ $# -eq 0 ]; then
    echo "Usage: ./send-message.sh RECIPIENT_PHONE_NUMBER [MESSAGE_TEXT]"
    echo "Example: ./send-message.sh +15551234567 \"Hello World\""
    echo "Example: ./send-message.sh +15551234567  (sends hello_world template)"
    exit 1
fi

RECIPIENT=$1
MESSAGE_TEXT=$2

echo "📱 Sending WhatsApp message..."
echo "From: ${TEST_FROM_NUMBER}"
echo "To: ${RECIPIENT}"

if [ -z "$MESSAGE_TEXT" ]; then
    # Send template message (hello_world)
    echo "📋 Sending template message: hello_world"
    
    RESPONSE=$(curl -s -i -X POST \
      "${API_BASE_URL}/${PHONE_NUMBER_ID}/messages" \
      -H "Authorization: Bearer ${ACCESS_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{
        \"messaging_product\": \"whatsapp\",
        \"to\": \"${RECIPIENT}\",
        \"type\": \"template\",
        \"template\": {
          \"name\": \"hello_world\",
          \"language\": {
            \"code\": \"en_US\"
          }
        }
      }")
else
    # Send text message
    echo "💬 Sending text message: ${MESSAGE_TEXT}"
    
    RESPONSE=$(curl -s -i -X POST \
      "${API_BASE_URL}/${PHONE_NUMBER_ID}/messages" \
      -H "Authorization: Bearer ${ACCESS_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{
        \"messaging_product\": \"whatsapp\",
        \"to\": \"${RECIPIENT}\",
        \"type\": \"text\",
        \"text\": {
          \"body\": \"${MESSAGE_TEXT}\"
        }
      }")
fi

echo "📡 Response:"
echo "$RESPONSE"

# Check if successful
if echo "$RESPONSE" | grep -q "200 OK"; then
    echo "✅ Message sent successfully!"
    MESSAGE_ID=$(echo "$RESPONSE" | grep -o '"wamid":"[^"]*' | cut -d'"' -f4)
    if [ ! -z "$MESSAGE_ID" ]; then
        echo "📨 Message ID: $MESSAGE_ID"
    fi
else
    echo "❌ Failed to send message"
    echo "Check your access token and phone number format"
fi
