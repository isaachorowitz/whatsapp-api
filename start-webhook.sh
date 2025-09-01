#!/bin/bash

# WhatsApp Webhook Server Startup Script
source cloud-api-config.env

echo "🚀 Starting WhatsApp Webhook Server..."
echo "📡 Port: ${WEBHOOK_PORT}"
echo "🔑 Verify Token: ${WEBHOOK_VERIFY_TOKEN}"
echo ""

# Start the webhook server in background
echo "🟢 Starting Node.js webhook server..."
npm start &
SERVER_PID=$!

# Wait a moment for server to start
sleep 3

# Check if server is running
if curl -s http://localhost:${WEBHOOK_PORT}/health > /dev/null; then
    echo "✅ Webhook server is running!"
    echo "🏥 Health check: http://localhost:${WEBHOOK_PORT}/health"
else
    echo "❌ Failed to start webhook server"
    kill $SERVER_PID 2>/dev/null
    exit 1
fi

echo ""
echo "🌐 Starting ngrok tunnel..."
echo "⏳ This will create a public URL for your webhook..."

# Start ngrok tunnel
ngrok http ${WEBHOOK_PORT} --log=stdout &
NGROK_PID=$!

echo ""
echo "📋 IMPORTANT: Copy the ngrok URL from above!"
echo ""
echo "🔧 Facebook Webhook Configuration:"
echo "   1. Go to your Facebook App → Webhooks"
echo "   2. Callback URL: https://YOUR_NGROK_URL.ngrok.io/webhook"
echo "   3. Verify Token: ${WEBHOOK_VERIFY_TOKEN}"
echo "   4. Subscribe to: messages, message_deliveries"
echo ""
echo "🛑 To stop both servers, press Ctrl+C or run:"
echo "   kill ${SERVER_PID} ${NGROK_PID}"
echo ""

# Wait for user to stop
trap "echo 'Stopping servers...'; kill $SERVER_PID $NGROK_PID 2>/dev/null; exit 0" INT

echo "✨ Webhook server is ready! Waiting for webhooks..."
echo "📱 Send a message to your WhatsApp number to test!"

# Keep script running
wait
