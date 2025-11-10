/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https"); // Using v2 onCall
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const axios = require("axios");
const dotenv = require('dotenv')
dotenv.config()

// Set global options for the functions.
setGlobalOptions({ maxInstances: 10 });

/**
 * Creates a Paymob payment key.
 * This function orchestrates the 3-step process to get a payment key from Paymob.
 *
 * @param {object} data - The data passed to the function from the client.
 * @param {number} data.amount - The payment amount in standard currency units.
 * @param {string} data.currency - The currency of the payment (e.g., "EGP").
 * @param {object} data.billingData - Customer's billing information.
 * @param {object} context - The context of the function call.
 * @return {Promise<{paymentKey: string}>} - A promise that resolves with the payment key.
 */
exports.createPaymobPaymentIntent = onCall(async (request) => {
  const {amount, currency, billingData} = request.data;

  // Ensure required data is present
  if (!amount || !currency || !billingData) {
    logger.error("Missing amount, currency, or billingData in request.", {
      data: request.data,
    });
    throw new HttpsError(
        "invalid-argument",
        "The function must be called with 'amount', 'currency', and 'billingData' arguments.",
    );
  }

  // IMPORTANT: Store your Paymob credentials securely using Firebase environment variables.
  // Do not hardcode them in your source code.
  // Run these commands in your terminal to set them:
  // firebase functions:config:set paymob.apikey="YOUR_PAYMOB_API_KEY"
  // firebase functions:config:set paymob.integrationid_card="YOUR_CARD_INTEGRATION_ID"
  const apiKey = process.env.PAYMOB_APIKEY;
  const integrationId = process.env.PAYMOB_INTEGRATIONID_CARD;

  if (!apiKey || !integrationId) {
    logger.error("Paymob API key or Integration ID is not configured.");
    throw new HttpsError("internal", "Server is not configured for payments.");
  }

  try {
    // Step 1: Authentication Request
    logger.info("Paymob: Kicking off payment for amount: " + amount);
    const authResponse = await axios.post("https://accept.paymob.com/api/auth/tokens", {
      "api_key": apiKey,
    });
    const authToken = authResponse.data.token;
    logger.info("Paymob: Auth token obtained.");

    // Step 2: Order Registration Request
    const amountInCents = amount * 100;
    const orderResponse = await axios.post("https://accept.paymob.com/api/ecommerce/orders", {
      "auth_token": authToken,
      "delivery_needed": "false",
      "amount_cents": amountInCents,
      "currency": currency,
      "items": [], // You can add items here if needed
    });
    const orderId = orderResponse.data.id;
    logger.info("Paymob: Order registered with ID: " + orderId);

    // Step 3: Payment Key Generation Request
    const paymentKeyResponse = await axios.post("https://accept.paymob.com/api/acceptance/payment_keys", {
      "auth_token": authToken,
      "amount_cents": amountInCents,
      "expiration": 3600,
      "order_id": orderId,
      "billing_data": billingData,
      "currency": currency,
      "integration_id": integrationId,
    });
    const paymentKey = paymentKeyResponse.data.token;
    logger.info("Paymob: Payment key generated successfully.");

    return {paymentKey: paymentKey};
  } catch (error) {
    logger.error("Error creating Paymob payment intent:", error.response ? error.response.data : error.message);
    throw new HttpsError("internal", "Unable to create payment intent.");
  }
});
