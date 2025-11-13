# Stripe Integration Setup for School Project

## Getting Test Keys

1. Go to [stripe.com](https://stripe.com) and create a free account
2. In your Stripe dashboard, make sure you're in "Test mode" (toggle in top right)
3. Go to Developers > API keys
4. Copy your "Publishable key" (starts with `pk_test_`)
5. Copy your "Secret key" (starts with `sk_test_`)

## Adding Keys to the Project

1. Open `scripts/PaymentManager.gd`
2. Replace the placeholder keys:
   ```gdscript
   const STRIPE_PUBLISHABLE_KEY = "pk_test_your_actual_key_here"
   const STRIPE_SECRET_KEY = "sk_test_your_actual_key_here"
   ```

## Test Cards

Use these test card numbers in your payment forms:
- **Successful payment**: 4242 4242 4242 4242
- **Declined payment**: 4000 0000 0000 0002
- **Insufficient funds**: 4000 0000 0000 9995

Use any future expiration date and any 3-digit CVC.

## Features Implemented

### Shop System
- Browse cosmetic bird colors
- View prices in USD
- Purchase with simulated Stripe integration
- Items are saved locally

### Payment Flow (Simulated)
- Creates payment intents
- Handles success/failure states
- Saves purchase data
- Updates shop UI

### Game Integration
- Bird colors change based on purchases
- High score tracking
- Save/load system for purchases

## Educational Value

This project demonstrates:
- Payment processing concepts
- User data persistence
- State management
- UI/UX for e-commerce
- Error handling
- Security considerations (test vs production keys)

## Important Notes

- **NEVER** use real payment keys in school projects
- **NEVER** commit API keys to version control
- This is for educational purposes only
- Real production apps need server-side payment processing
- Proper webhook handling required for production

## Next Steps for Learning

1. Implement proper server-side payment processing
2. Add webhook handling for payment confirmations
3. Implement user authentication
4. Add proper error handling and retry logic
5. Study PCI compliance requirements