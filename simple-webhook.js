const express = require('express');
const app = express();

const PORT = 3000;
const VERIFY_TOKEN = 'my_webhook_verify_token_123';

console.log('🚀 Starting simple webhook server...');

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check
app.get('/health', (req, res) => {
    console.log('📊 Health check requested');
    res.json({ 
        status: 'OK', 
        timestamp: new Date(),
        webhook_verify_token: VERIFY_TOKEN,
        port: PORT
    });
});

// Webhook verification
app.get('/webhook', (req, res) => {
    console.log('📞 Webhook verification request received');
    console.log('Query params:', req.query);
    
    const mode = req.query['hub.mode'];
    const token = req.query['hub.verify_token'];
    const challenge = req.query['hub.challenge'];
    
    if (mode === 'subscribe' && token === VERIFY_TOKEN) {
        console.log('✅ Webhook verified successfully!');
        res.status(200).send(challenge);
    } else {
        console.log('❌ Webhook verification failed');
        res.sendStatus(403);
    }
});

// Webhook endpoint
app.post('/webhook', (req, res) => {
    console.log('📨 Webhook POST received');
    console.log('Body:', JSON.stringify(req.body, null, 2));
    
    if (req.body.object === 'whatsapp_business_account') {
        console.log('✅ WhatsApp webhook event received');
        
        // Process messages
        req.body.entry?.forEach(entry => {
            entry.changes?.forEach(change => {
                if (change.field === 'messages') {
                    const messages = change.value?.messages || [];
                    messages.forEach(message => {
                        console.log('📩 Message from:', message.from);
                        console.log('📝 Text:', message.text?.body || '[non-text message]');
                    });
                }
            });
        });
    }
    
    res.status(200).send('EVENT_RECEIVED');
});

// Start server
app.listen(PORT, () => {
    console.log(`✅ Webhook server running on port ${PORT}`);
    console.log(`🏥 Health check: http://localhost:${PORT}/health`);
    console.log(`🔗 Webhook URL: http://localhost:${PORT}/webhook`);
    console.log(`🔑 Verify token: ${VERIFY_TOKEN}`);
});
