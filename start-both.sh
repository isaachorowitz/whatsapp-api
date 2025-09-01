#!/bin/bash

echo "🚀 Starting WhatsApp Webhook Setup..."

# Kill any existing processes
pkill -f "simple-webhook" 2>/dev/null
pkill -f "ngrok" 2>/dev/null
sleep 2

echo "📡 Starting webhook server..."
node simple-webhook.js &
WEBHOOK_PID=$!

# Wait for webhook server
sleep 3

# Test webhook server
if curl -s http://localhost:3000/health > /dev/null; then
    echo "✅ Webhook server is running!"
else
    echo "❌ Webhook server failed to start"
    kill $WEBHOOK_PID 2>/dev/null
    exit 1
fi

echo "🌐 Starting ngrok tunnel..."
ngrok http 3000 --log=stdout &
NGROK_PID=$!

# Wait for ngrok to be ready
echo "⏳ Waiting for ngrok to start..."
sleep 8

# Get ngrok URL
NGROK_URL=""
for i in {1..10}; do
    NGROK_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | grep -o '"public_url":"https://[^"]*' | head -1 | cut -d'"' -f4)
    if [ ! -z "$NGROK_URL" ]; then
        break
    fi
    echo "⏳ Still waiting for ngrok... (attempt $i/10)"
    sleep 2
done

if [ -z "$NGROK_URL" ]; then
    echo "❌ Failed to get ngrok URL"
    kill $WEBHOOK_PID $NGROK_PID 2>/dev/null
    exit 1
fi

echo ""
echo "🎉 SUCCESS! Both services are running!"
echo ""
echo "📋 FACEBOOK WEBHOOK CONFIGURATION:"
echo "   Callback URL: ${NGROK_URL}/webhook"
echo "   Verify Token: my_webhook_verify_token_123"
echo ""
echo "🔧 Steps to configure:"
echo "1. Go to your Facebook Developer Console"
echo "2. Navigate to WhatsApp → Configuration → Webhook"
echo "3. Enter the Callback URL above"
echo "4. Enter the Verify Token above"
echo "5. Subscribe to 'messages' and 'message_deliveries'"
echo ""
echo "🧪 Test your webhook:"
echo "   curl '${NGROK_URL}/webhook?hub.mode=subscribe&hub.verify_token=my_webhook_verify_token_123&hub.challenge=test123'"
echo ""
echo "🛑 To stop: kill $WEBHOOK_PID $NGROK_PID"

# Keep running
trap "echo 'Stopping...'; kill $WEBHOOK_PID $NGROK_PID 2>/dev/null; exit 0" INT
echo "✨ Services running! Press Ctrl+C to stop."
wait
