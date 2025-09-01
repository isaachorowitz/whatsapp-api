const express = require('express');
const crypto = require('crypto');
const app = express();

// For Node.js versions that don't have fetch built-in
const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));

// Load configuration
const fs = require('fs');

// Simple config loader
const config = {};
if (fs.existsSync('./cloud-api-config.env')) {
    const configContent = fs.readFileSync('./cloud-api-config.env', 'utf8');
    configContent.split('\n').forEach(line => {
        if (line.includes('=') && !line.startsWith('#')) {
            const [key, value] = line.split('=');
            config[key.trim()] = value.trim();
        }
    });
}

// Set environment variables
Object.keys(config).forEach(key => {
    if (!process.env[key]) {
        process.env[key] = config[key];
    }
});

const PORT = process.env.WEBHOOK_PORT || 3000;
const VERIFY_TOKEN = process.env.WEBHOOK_VERIFY_TOKEN || 'my_webhook_verify_token_123';
const APP_SECRET = process.env.APP_SECRET; // Optional: for signature verification

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Webhook verification (required by Facebook)
app.get('/webhook', (req, res) => {
    console.log('📞 Webhook verification request received');
    
    const mode = req.query['hub.mode'];
    const token = req.query['hub.verify_token'];
    const challenge = req.query['hub.challenge'];
    
    console.log('Mode:', mode);
    console.log('Token:', token);
    console.log('Expected token:', VERIFY_TOKEN);
    
    // Check if a token and mode were sent
    if (mode && token) {
        // Check the mode and token sent are correct
        if (mode === 'subscribe' && token === VERIFY_TOKEN) {
            console.log('✅ Webhook verified successfully!');
            res.status(200).send(challenge);
        } else {
            console.log('❌ Webhook verification failed - token mismatch');
            res.sendStatus(403);
        }
    } else {
        console.log('❌ Webhook verification failed - missing parameters');
        res.sendStatus(400);
    }
});

// Webhook endpoint to receive messages
app.post('/webhook', (req, res) => {
    console.log('📨 Webhook POST request received');
    console.log('Headers:', JSON.stringify(req.headers, null, 2));
    console.log('Body:', JSON.stringify(req.body, null, 2));
    
    // Verify the request signature (optional but recommended)
    if (APP_SECRET) {
        const signature = req.headers['x-hub-signature-256'];
        if (signature) {
            const expectedSignature = 'sha256=' + crypto
                .createHmac('sha256', APP_SECRET)
                .update(JSON.stringify(req.body))
                .digest('hex');
            
            if (signature !== expectedSignature) {
                console.log('❌ Invalid signature');
                return res.sendStatus(403);
            }
            console.log('✅ Signature verified');
        }
    }
    
    const body = req.body;
    
    // Check if this is a WhatsApp webhook event
    if (body.object === 'whatsapp_business_account') {
        console.log('📱 WhatsApp Business Account webhook received');
        
        // Process each entry
        body.entry.forEach(entry => {
            console.log('📋 Processing entry:', entry.id);
            
            // Process webhook events
            const changes = entry.changes || [];
            changes.forEach(change => {
                console.log('🔄 Processing change:', change.field);
                
                if (change.field === 'messages') {
                    const value = change.value;
                    console.log('💬 Message event:', JSON.stringify(value, null, 2));
                    
                    // Process messages
                    if (value.messages) {
                        value.messages.forEach(message => {
                            console.log('📩 Received message:');
                            console.log('  From:', message.from);
                            console.log('  ID:', message.id);
                            console.log('  Timestamp:', new Date(message.timestamp * 1000));
                            console.log('  Type:', message.type);
                            
                            if (message.text) {
                                console.log('  Text:', message.text.body);
                            }
                            
                            // Here you can add your business logic
                            handleIncomingMessage(message, value);
                        });
                    }
                    
                    // Process message status updates
                    if (value.statuses) {
                        value.statuses.forEach(status => {
                            console.log('📊 Message status update:');
                            console.log('  Message ID:', status.id);
                            console.log('  Status:', status.status);
                            console.log('  Timestamp:', new Date(status.timestamp * 1000));
                            
                            handleMessageStatus(status);
                        });
                    }
                }
            });
        });
        
        res.status(200).send('EVENT_RECEIVED');
    } else {
        console.log('❌ Not a WhatsApp webhook event');
        res.sendStatus(404);
    }
});

// Function to send replies back to WhatsApp
async function sendReply(toPhoneNumber, messageText) {
    const url = `${process.env.API_BASE_URL}/${process.env.PHONE_NUMBER_ID}/messages`;
    
    const payload = {
        messaging_product: "whatsapp",
        to: toPhoneNumber,
        type: "text",
        text: {
            body: messageText
        }
    };
    
    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${process.env.ACCESS_TOKEN}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(payload)
        });
        
        const result = await response.json();
        console.log('✅ Message sent successfully:', result);
        return result;
    } catch (error) {
        console.error('❌ Error sending message:', error);
        return null;
    }
}

// Customer Support Bot Logic
function generateSupportResponse(messageText) {
    const text = messageText.toLowerCase();
    
    // FAQ Responses for Baba App
    if (text.includes('help') || text.includes('support')) {
        return "👋 Hi! I'm here to help with your Baba app questions. You can ask me about:\n\n• Account issues\n• App features\n• Technical problems\n• Billing questions\n\nWhat can I help you with?";
    }
    
    if (text.includes('account') || text.includes('login') || text.includes('password')) {
        return "🔐 For account issues:\n\n1. Try resetting your password in the app\n2. Check your email for verification links\n3. Make sure you're using the correct email\n\nStill having trouble? Reply with 'agent' to speak with a human.";
    }
    
    if (text.includes('app') && (text.includes('crash') || text.includes('not working') || text.includes('bug'))) {
        return "🔧 For app issues:\n\n1. Try force-closing and reopening the app\n2. Update to the latest version\n3. Restart your phone\n\nIf the problem continues, reply with your phone model and OS version.";
    }
    
    if (text.includes('billing') || text.includes('payment') || text.includes('subscription')) {
        return "💳 For billing questions:\n\n• Check your subscription status in app settings\n• Payment issues? Verify your payment method\n• Need a refund? Reply with 'refund' and your order details\n\nNeed more help? Reply 'agent' for human support.";
    }
    
    if (text.includes('agent') || text.includes('human') || text.includes('person')) {
        return "🙋‍♀️ I'll connect you with a human agent. Please describe your issue in detail and someone from our team will respond within 2 hours during business hours (9AM-6PM EST).";
    }
    
    // Default response
    return "Thanks for contacting Baba support! 🌟\n\nI can help with:\n• Account & login issues\n• App problems\n• Billing questions\n• General support\n\nJust describe your issue or type 'help' for more options. For urgent matters, reply 'agent' to reach a human.";
}

// Function to handle incoming messages
function handleIncomingMessage(message, value) {
    console.log('🎯 Processing incoming message...');
    console.log('📱 From:', message.from);
    console.log('💬 Message:', message.text?.body || `[${message.type}]`);
    
    // Handle text messages with customer support responses
    if (message.type === 'text') {
        const supportResponse = generateSupportResponse(message.text.body);
        
        console.log('🤖 Sending support response:', supportResponse);
        
        // Send the response
        sendReply(message.from, supportResponse);
    } else {
        // Handle non-text messages (images, documents, etc.)
        const fallbackResponse = "I received your message! For the best support experience, please send text messages. How can I help you with the Baba app today?";
        console.log('🤖 Sending fallback response for', message.type);
        sendReply(message.from, fallbackResponse);
    }
    
    // Log the message to a file or database
    const logEntry = {
        timestamp: new Date(),
        from: message.from,
        message_id: message.id,
        type: message.type,
        content: message.text ? message.text.body : `[${message.type}]`
    };
    
    console.log('💾 Message logged:', JSON.stringify(logEntry, null, 2));
}

// Function to handle message status updates
function handleMessageStatus(status) {
    console.log('📈 Processing message status...');
    
    const statusLog = {
        timestamp: new Date(),
        message_id: status.id,
        status: status.status,
        recipient_id: status.recipient_id
    };
    
    console.log('📊 Status logged:', JSON.stringify(statusLog, null, 2));
}

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        timestamp: new Date(),
        webhook_verify_token: VERIFY_TOKEN
    });
});

// Start the server
app.listen(PORT, () => {
    console.log('🚀 Webhook server running on port', PORT);
    console.log('🔑 Verify token:', VERIFY_TOKEN);
    console.log('📡 Webhook URL will be: http://your-domain/webhook');
    console.log('🏥 Health check: http://localhost:' + PORT + '/health');
    console.log('');
    console.log('📋 Next steps:');
    console.log('1. Install dependencies: npm install express dotenv');
    console.log('2. Set up ngrok tunnel: ngrok http ' + PORT);
    console.log('3. Use the ngrok URL in Facebook webhook configuration');
    console.log('4. Use verify token: ' + VERIFY_TOKEN);
});

module.exports = app;
