# WhatsApp Cloud API Setup

## ✅ Your Configuration
- **Access Token**: Configured ✓
- **Test Phone**: +1 555 192 3566
- **Your Business Phone**: +1 555-793-6692 (needs verification)
- **Phone Number ID**: 697919100082149
- **WABA ID**: 1116379416662470

## 🚀 Quick Commands

### Send Messages
```bash
# Send template message
./send-message.sh +1234567890

# Send custom text message  
./send-message.sh +1234567890 "Your message here"
```

### Verify Account
```bash
./verify-cloud-account.sh
```

## 📋 Next Steps

### 1. Add Your Business Number
- Go to [business.facebook.com](https://business.facebook.com)
- Add phone number: `+1 555-793-6692`
- Use certificate: `CmgKJAi/667jweutAhIGZW50OndhIgtiYWJhIUhlYnJld1C37tXFBhpAMeMsc52hAUx6jtOKo5iixqKrZn581nFFgXNDcwIRSnUbZeyL+2bbbnm8e1+wzIZyopeV0kkEbvh/3pjt5mk0ABIubUpSuqzXm/TwWrWznaloLpxZ4uNVx9iqqBlETq08f3sWyuDKcMwOJs3OjkOtKQ==`

### 2. Add Recipients
Recipients must:
- Be added to your allowed list in Facebook Business Manager, OR
- Message you first to opt-in

### 3. Message Templates
- Use pre-approved templates for marketing messages
- Text messages work for customer service (after they message you first)

## 🔧 Files Created
- `cloud-api-config.env` - Your API configuration
- `send-message.sh` - Send messages script
- `verify-cloud-account.sh` - Account verification script

## 📚 Resources
- [WhatsApp Cloud API Docs](https://developers.facebook.com/docs/whatsapp/cloud-api)
- [Facebook Business Manager](https://business.facebook.com)
- [Message Templates](https://developers.facebook.com/docs/whatsapp/message-templates)

---
*Your WhatsApp Business API is ready to use! 🎉*
