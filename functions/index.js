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
const dotenv = require("dotenv");
dotenv.config();
const admin = require("firebase-admin");
const {
  VertexAI,
  HarmCategory,
  HarmBlockThreshold,
} = require("@google-cloud/vertexai");
admin.initializeApp();

// Set global options for the functions.
setGlobalOptions({maxInstances: 10});
/**
 * Creates a Paymob payment key.
 * This function orchestrates the 3-step process to get a payment key from
 * Paymob.
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
        "The function must be called with 'amount', 'currency', and 'billingData' " +
        "arguments.",
    );
  }

  // IMPORTANT: Store your Paymob credentials securely using Firebase
  // environment variables.
  // Do not hardcode them in your source code.
  // Run these commands in your terminal to set them:
  // firebase functions:config:set paymob.apikey="YOUR_PAYMOB_API_KEY"
  // firebase functions:config:set paymob.integrationid_card="YOUR_ID"
  const apiKey = process.env.PAYMOB_APIKEY;
  const integrationId = process.env.PAYMOB_INTEGRATIONID_CARD;

  if (!apiKey || !integrationId) {
    logger.error("Paymob API key or Integration ID is not configured.");
    throw new HttpsError("internal", "Server is not configured for payments");
  }

  try {
    // Step 1: Authentication Request
    logger.info("Paymob: Kicking off payment for amount: " + amount); // eslint-disable-line max-len
    const authResponse = await axios.post("https://accept.paymob.com/api/auth/tokens", {
      "api_key": apiKey,
    });
    const authToken = authResponse.data.token; // eslint-disable-line max-len
    logger.info("Paymob: Auth token obtained.");

    // Step 2: Order Registration Request
    const amountInCents = amount * 100;
    const orderResponse = await axios.post("https://accept.paymob.com/api/ecommerce/orders", {
      "auth_token": authToken,
      "delivery_needed": "false",
      "amount_cents": amountInCents,
      "currency": currency,
      "items": [], // You can add items here if needed // eslint-disable-line max-len
    });
    const orderId = orderResponse.data.id;
    logger.info("Paymob: Order registered with ID: " + orderId);

    // Step 3: Payment Key Generation Request
    const paymentKeyResponse = await
    axios.post("https://accept.paymob.com/api/acceptance/payment_keys", {
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
    const errorMessage = error.response ? error.response.data : error.message;
    logger.error("Error creating Paymob payment intent:", errorMessage);
    throw new HttpsError("internal", "Unable to create payment intent.");
  }
});

// --- 1. Define AI Personalities (System Prompts & Tools) ---

const extractOrderFunction = {
  name: "extractOrder",
  description: "Extracts order details from a user's grocery list",
  parameters: {
    type: "OBJECT",
    properties: {
      items: {
        type: "ARRAY",
        description: "A list of grocery items. Each item is an object.",
        items: {
          type: "OBJECT",
          properties: {
            item: {
              type: "STRING", // eslint-disable-line max-len
              description: "The name of the grocery item (e.g., 'milk', " + // eslint-disable-line max-len
                           "'bread', 'apples').",
            },
            quantity: {
              type: "NUMBER",
              description: "The count or amount of the item. Defaults to 1 " +
                           "if not specified.",
            },
            unit: {
              type: "STRING", // eslint-disable-line max-len
              description: "The unit of measurement (e.g., 'kg', 'liter', " + // eslint-disable-line max-len
                           "'pack', 'loaves'). Optional.",
            },
          },
          required: ["item", "quantity"],
        },
      },
      store: {
        type: "STRING", // eslint-disable-line max-len
        description: "The name or type of store (e.g., 'supermarket', " + // eslint-disable-line max-len
                     "'bakery'). Optional.",
      },
      notes: {
        type: "STRING", // eslint-disable-line max-len
        description: "Any additional notes or preferences from the user. " + // eslint-disable-line max-len
                     "Optional.",
      },
    },
    required: ["items"],
  },
};

const getModelConfig = (modelType) => {
  switch (modelType) {
    case "order":
      return {
        systemInstruction: {
          parts: [
            {
              text: "You are \"Suefery\", an expert grocery and delivery " + // eslint-disable-line max-len
                    "order assistant in Egypt. Your role is to receive " + // eslint-disable-line max-len
                    "unstructured text from a user and convert it *only* " + // eslint-disable-line max-len
                    "into a structured JSON format using the `extractOrder` " + // eslint-disable-line max-len
                    "function. You must understand Egyptian Arabic " + // eslint-disable-line max-len
                    "(colloial) and English. If a quantity isn't specified, " + // eslint-disable-line max-len
                    "default to 1. Do not respond with conversational text. " +
                    "Only call the function.",
            },
          ],
        },
        tools: [{functionDeclarations: [extractOrderFunction]}],
      };
    case "chef":
      return {
        systemInstruction: {
          parts: [{
            text: "You are \"Chef Suefery\", a helpful and creative " +
                  "Egyptian chef. You specialize in simple, delicious " +
                  "recipes that can be made from common household " +
                  "ingredients. You must respond in the user's language " +
                  "(Egyptian Arabic or English). Your tone is encouraging, " +
                  "friendly, and warm. Keep recipes concise and easy to " +
                  "follow.",
          }],
        },
        tools: [],
      };
    case "general":
    default:
      return {
        systemInstruction: {
          parts: [{
            text: "You are \"Suefery\", a general-purpose helpful assistant " + // eslint-disable-line max-len
                  "for a delivery app. You can answer questions about the " + // eslint-disable-line max-len
                  "service, chat with the user, or provide general help. " + // eslint-disable-line max-len
                  "You must respond in the user's language (Egyptian " + // eslint-disable-line max-len
                  "Arabic or English). Your tone is polite, professional, " + // eslint-disable-line max-len
                  "and helpful.", // eslint-disable-line max-len
          }],
        },
        tools: [],
      };
  }
};

// --- 2. The Cloud Function (Refactored for Vertex AI) ---
exports.geminiProxy = onCall(
    {
      // Enforce App Check (still vital!)
      enforceAppCheck: true,
      // We no longer need secrets!
      region: "us-central1", // Make sure this matches your Vertex AI region
    },
    async (request) => {
      // 1. Get data from the app (and check auth)
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "You must be logged in.");
      }
      const {history, modelType} = request.data;
      if (!history || !modelType) {
        throw new HttpsError("invalid-argument", "Missing 'history' or 'modelType'.");
      }

      // 2. Initialize Vertex AI
      // Project ID is automatically read from the function's environment
      const project = process.env.GCLOUD_PROJECT;
      const location = "us-central1"; // Must be a supported Gemini region

      if (!project || project !== "suefery-d2bf2") {
        throw new HttpsError("internal", "Function is not running in the " +
          `correct project. Expected 'suefery-d2bf2' but found '${project}'.`);
      }

      const vertexAI = new VertexAI({project, location});

      // 3. Get the correct AI personality
      const config = getModelConfig(modelType);
      const model = vertexAI.getGenerativeModel({
        // Use the Vertex AI model name
        model: "gemini-1.5-flash-001",
        systemInstruction: config.systemInstruction,
        tools: config.tools,
      });

      // 4. Set safety settings (same as before)
      const safetySettings = [
        {
          category: HarmCategory.HARM_CATEGORY_HARASSMENT,
          threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
        },
        // ... add other categories as needed
      ];

      // 5. Format history for the API (same as before)
      const contentHistory = history.map((msg) => ({
        role: msg.role, // 'user' or 'model'
        parts: [{text: msg.text}],
      }));
      const lastMessage = contentHistory.pop();
      if (!lastMessage || lastMessage.role !== "user") {
        throw new HttpsError("invalid-argument", "Last message must be from user.");
      }

      // 6. Call the Vertex AI Gemini API
      try {
        const chat = model.startChat({history: contentHistory, safetySettings});
        const result = await chat.sendMessage(lastMessage.parts[0].text);
        const response = result.response;

        // 7. Process the response
        const candidate = response.candidates?.[0];
        if (!candidate || !candidate.content || !candidate.content.parts) {
          throw new HttpsError("internal", "Invalid AI response structure.");
        }

        // Check for a function call first
        const functionCall = candidate.content.parts.find(
            (part) => part.functionCall,
        )?.functionCall;

        if (functionCall) {
          // It's an order! Return the structured JSON.
          return functionCall.args;
        }

        // If no function call, join all text parts
        const text = candidate.content.parts
            .filter((part) => part.text)
            .map((part) => part.text)
            .join("");

        if (text) {
          // It's a chat message. Return the text.
          return {text: text};
        }

        // No response
        return {text: "Sorry, I'm not sure how to respond to that."};
      } catch (error) {
        console.error("Error calling Vertex AI API:", error);
        throw new HttpsError(
            "internal", "Failed to communicate with AI.", error.message,
        );
      }
    },
);
