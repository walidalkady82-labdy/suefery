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

// --- 1. Define a SINGLE AI Personality (System Prompt) ---
const systemInstruction = {
  parts: [{
    text: "You are \"Suefery\", a multi-talented assistant for a delivery app " +
          "in Egypt. You can act in several roles based on the user's needs, " +
          "which are defined by your available tools. You must understand " +
          "and respond in both Egyptian Arabic (colloquial) and English.\n\n" +
          "Your roles are:\n" +
          "1.  **Order Assistant**: When a user wants to order food or " +
          "groceries, use the `createOrder` tool to structure their request.\n" +
          "2.  **Chef**: If a user asks for cooking ideas, use the " +
          "`suggestRecipe` tool to provide a recipe.\n" +
          "3.  **Helpful Guide**: If the user asks for help, use the `getHelp` " +
          "tool.\n\n" +
          "Your primary goal is to analyze the user's message and decide if " +
          "it matches one of your tools. If it does not (e.g., they are " +
          "making small talk or asking a general question), just respond " +
          "naturally and conversationally as a friendly assistant.",
  }],
};

// --- NEW: Define all function tools here ---
const functionDeclarations = [
  {
    name: "createOrder",
    description: "Creates a new food order from a list of items.",
    parameters: {
      type: "OBJECT",
      properties: {
        aiResponseText: {
          type: "STRING",
          description: "A friendly, conversational confirmation message to show the user in their language (e.g., 'You got it! I have your order for... Is that correct?').",
        },
        items: {
          type: "ARRAY",
          description: "A list of food items to order.",
          items: {
            type: "OBJECT",
            properties: {
              itemName: {type: "STRING", description: "The name of the item."},
              quantity: {type: "NUMBER", description: "The quantity of the item."},
              notes: {type: "STRING", description: "Optional notes for the item, like 'large' or 'extra spicy'."}
            },
            required: ["itemName", "quantity"],
          },
        },
      },
      required: ["items", "aiResponseText"],
    },
  },
  {
    name: "suggestRecipe",
    description: "Suggests a recipe for the user.",
    parameters: {
      type: "OBJECT",
      properties: {
        recipeName: {type: "STRING"},
        imageUrl: {type: "STRING"},
        ingredients: {type: "ARRAY", items: {type: "STRING"}},
        instructions: {type: "ARRAY", items: {type: "STRING"}},
      },
      required: ["recipeName", "ingredients", "instructions"],
    },
  },
  {
    name: "buildOrderFromRecipe",
    description: "Creates a new food order based on the ingredients of a previously suggested recipe.",
    parameters: {
      type: "OBJECT",
      properties: {
        recipeName: {type: "STRING", description: "The name of the recipe to order ingredients for."},
        aiResponseText: {type: "STRING", description: "A confirmation message for ordering the recipe ingredients."},
      },
      required: ["recipeName", "aiResponseText"],
    },
  },
  {
    name: "cancelOrder",
    description: "Cancels the current pending order proposal.",
    parameters: {
      type: "OBJECT",
      properties: {
        aiResponseText: {type: "STRING", description: "A confirmation message that the order was cancelled."},
      },
      required: ["aiResponseText"],
    },
  },
  {
    name: "getHelp",
    description: "Provides a help message about the app.",
    parameters: {
      type: "OBJECT",
      properties: {
        helpText: {type: "STRING"},
      },
      required: ["helpText"],
    },
  },
];

// --- 2. The Cloud Function (Refactored for Vertex AI) ---
exports.geminiProxy = onCall(
    {
      // Enforce App Check (still vital!)
      enforceAppCheck: true,
      // --- ADDITION: Add rate limiting ---
      // This limits each function instance to 15 calls per minute.
      rateLimits: {
        timePeriod: "60s",
        maxCalls: 15,
      },
      // We no longer need secrets!
      region: "us-central1", // Make sure this matches your Vertex AI region
    },
    async (request) => {
      // 1. Get data from the app (and check auth)
      console.log("geminiProxy: triggered!");
      console.log("geminiProxy: checking auth!");
      if (!request.auth) {
        console.log("geminiProxy: unauthenticated You must be logged in.!");
        throw new HttpsError("unauthenticated", "You must be logged in.");
      }
      console.log("geminiProxy: auth ok!"); 
      const {history} = request.data;

      if (!history) {
        throw new HttpsError("invalid-argument", "Missing 'history' or 'tools' parameter.");
      }

      // 2. Initialize Vertex AI
      // Project ID is automatically read from the function's environment
      const project = process.env.GCLOUD_PROJECT;
      console.log(project);
      const location = "us-central1"; // Must be a supported Gemini region

      if (!project || project !== "suefery-d2bf2") {
        throw new HttpsError("internal", "Function is not running in the " +
          `correct project. Expected 'suefery-d2bf2' but found '${project}'.`);
      }

      const vertexAI = new VertexAI({project, location});

      // 3. Get the correct AI personality
      const model = vertexAI.getGenerativeModel({
        // Use the Vertex AI model name
        model: "gemini-2.5-flash",
        systemInstruction: systemInstruction,
        tools: [{functionDeclarations: functionDeclarations}],
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
        const toolCall = candidate.content.parts.find(
            (part) => part.functionCall,
        )?.functionCall;

        if (toolCall) {
          // It's a tool call! Return the structured JSON.
          logger.info(`AI is calling tool: ${toolCall.name} with args: ${JSON.stringify(toolCall.args)}`);
          return {toolCall: {name: toolCall.name, arguments: toolCall.args}};
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
        // --- REFACTORED: More detailed error handling ---
        logger.error("Error calling Vertex AI API:", {
          // Log the full error object for detailed inspection in Cloud Logging
          errorObject: JSON.stringify(error, Object.getOwnPropertyNames(error)),
        });

        // Check if the response was blocked due to safety settings
        if (error.response && error.response.promptFeedback &&
            error.response.promptFeedback.blockReason) {
          logger.warn("AI response blocked due to safety settings.", {
            reason: error.response.promptFeedback.blockReason,
          });
          throw new HttpsError(
              "invalid-argument",
              "Your request was blocked for safety reasons. Please rephrase your message.",
          );
        }

        // For other errors, throw a more generic but still informative error.
        throw new HttpsError(
            "unavailable", // Use 'unavailable' to indicate a backend service failed
            "The AI service is currently unavailable. Please try again later.",
            {originalMessage: error.message}, // Pass original error for client-side logging
        );
      }
    },
);
