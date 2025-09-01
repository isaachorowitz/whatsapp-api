#!/bin/bash

echo "🚀 Starting WhatsApp Webhook with LocalTunnel (no signup required)..."

# Kill any existing processes
pkill -f "simple-webhook" 2>/dev/null
pkill -f "lt --port" 2>/dev/null
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

echo "📦 Installing localtunnel..."
npm install -g localtunnel 2>/dev/null || echo "localtunnel already installed"

echo "🌐 Starting localtunnel..."
lt --port 3000 --print-requests &
TUNNEL_PID=$!

# Wait for tunnel
echo "⏳ Waiting for tunnel to start..."
sleep 5

echo ""
echo "🎉 SUCCESS! Webhook server is running!"
echo ""
echo "📋 FACEBOOK WEBHOOK CONFIGURATION:"
echo "   Callback URL: [Check the localtunnel output above for URL]/webhook"
echo "   Verify Token: my_webhook_verify_token_123"
echo ""
echo "🔧 Steps to configure:"
echo "1. Copy the https://XXXXX.loca.lt URL from above"
echo "2. Go to Facebook Developer Console → WhatsApp → Webhook"
echo "3. Enter: https://XXXXX.loca.lt/webhook"
echo "4. Enter verify token: my_webhook_verify_token_123"
echo "5. Subscribe to 'messages' and 'message_deliveries'"
echo ""
echo "🛑 To stop: kill $WEBHOOK_PID $TUNNEL_PID"

# Keep running
trap "echo 'Stopping...'; kill $WEBHOOK_PID $TUNNEL_PID 2>/dev/null; exit 0" INT
echo "✨ Services running! Press Ctrl+C to stop."
wait
