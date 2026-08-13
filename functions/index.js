// ============================================================
// Biteo Razorpay Backend (FINAL FIXED VERSION)
// ============================================================

const { onRequest } = require("firebase-functions/v2/https");
const { defineString } = require("firebase-functions/params");
const admin = require("firebase-admin");
const crypto = require("crypto");
const Razorpay = require("razorpay");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const cors = require("cors")({ origin: true });

admin.initializeApp();
const db = admin.firestore();

// 🔐 Secrets
const RAZORPAY_KEY_ID = defineString("RAZORPAY_KEY_ID");
const RAZORPAY_KEY_SECRET = defineString("RAZORPAY_KEY_SECRET");
const GEMINI_API_KEY = defineString("GEMINI_API_KEY");

// ============================================================
// CREATE ORDER
// ============================================================
exports.createOrder = onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const data =
        typeof req.body === "string" ? JSON.parse(req.body) : req.body;

      const {
  userId,
  amount,
  mode = "pickup",

  // NEW
  restaurant_note = "",
  no_cutlery = false,
} = data;

      if (!userId) {
        return res.status(400).json({ message: "UserId required" });
      }

      // 🔥 Read cart
      let finalAmount = amount;

      const cartSnap = await db
        .collection("active_carts")
        .doc(userId)
        .get();

      if (cartSnap.exists) {
        const cart = cartSnap.data();
        finalAmount = cart?.pricing?.total ?? amount;
      }

      if (!finalAmount) {
        return res.status(400).json({ message: "Invalid amount" });
      }

      const razorpay = new Razorpay({
        key_id: RAZORPAY_KEY_ID.value(),
        key_secret: RAZORPAY_KEY_SECRET.value(),
      });

      const order = await razorpay.orders.create({
        amount: finalAmount,
        currency: "INR",
        receipt: `rcpt_${Date.now()}`,
      });

      return res.json({
  success: true,
  order,
  mode, // ✅ send back
});
    } catch (e) {
      console.error("CREATE ORDER ERROR:", e);
      return res.status(500).json({ error: e.message });
    }
  });
});

// ============================================================
// VERIFY PAYMENT
// ============================================================
exports.verifyPayment = onRequest((req, res) => {
  cors(req, res, async () => {
    try {
      const data =
        typeof req.body === "string" ? JSON.parse(req.body) : req.body;

const {
  razorpay_order_id,
  razorpay_payment_id,
  razorpay_signature,
  userId,
  orderData,
  mode = "pickup",
  vendor_id,

  // NEW
  restaurant_note = "",
  no_cutlery = false,
} = data;

      // 🔐 Signature verify
      const body = razorpay_order_id + "|" + razorpay_payment_id;

      const expectedSignature = crypto
        .createHmac("sha256", RAZORPAY_KEY_SECRET.value())
        .update(body)
        .digest("hex");

      if (expectedSignature !== razorpay_signature) {
        return res.status(400).json({
          success: false,
          message: "Invalid signature",
        });
      }

      // 🔥 Fetch cart
      const cartRef = db.collection("active_carts").doc(userId);
      const cartSnap = await cartRef.get();

      let items = orderData?.items ?? [];
let amount = 0;
let vendorName = "Biteo Vendor";

if (cartSnap.exists) {
  const cart = cartSnap.data();

  items = cart.items ?? items;
  amount = cart?.pricing?.total ?? amount;

  // ✅ FINAL FIX (handles all cases)
  vendorName =
    cart?.vendorName ||
    cart?.vendor_name ||
    cart?.restaurantName ||
    cart?.name ||
    "Biteo Vendor";
}
let vendorId = vendor_id ?? null; // 🔥 ADD THIS

      if (cartSnap.exists) {
  const cart = cartSnap.data();

  items = cart.items ?? items;
  // 🔥 FORCE CORRECT AMOUNT
if (cart?.pricing?.total) {
  amount = cart.pricing.total;
} else if (cart?.totalPaise) {
  amount = cart.totalPaise;
} else if (cart?.items) {
  // 🔥 LAST FALLBACK: calculate manually
  amount = cart.items.reduce((sum, item) => {
    return sum + (item.price ?? 0) * (item.quantity ?? 1);
  }, 0);
} else {
  amount = 0;
}

console.log("🔥 FINAL AMOUNT:", amount);
  vendorName = cart?.vendorName ?? vendorName;

  // 🔥 fallback if not sent from app
  if (!vendorId) {
    vendorId = cart?.vendorId ?? cart?.vendor_id ?? null;
  }
}

// ✅ 🔥 ADD THIS BLOCK HERE (OUTSIDE the if)
if (!vendorId) {
  console.log("❌ Vendor ID missing (backend)");
  return res.status(400).json({
    success: false,
    message: "Vendor ID missing",
  });
}

// 🔥 NOW OTP CODE STARTS
let otpCode = null;

if (mode === "pickup") {
  otpCode = Math.floor(1000 + Math.random() * 9000).toString();
}

      // 🔥 Create order
      const orderRef = db.collection("orders").doc();

    await orderRef.set({
  id: orderRef.id,
  user_id: userId,
  vendor_id: vendorId, // 🔥 ADD THIS LINE
  items,
  amount,
  mode,
  otpCode,
  vendorName,

  restaurantNote: restaurant_note,
noCutlery: no_cutlery,

        razorpay_order_id,
        razorpay_payment_id,
        status: "pending",
        created_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 🔥 Delete cart
      if (cartSnap.exists) {
        await cartRef.delete();
      }

      // 🔥 Response to app
     return res.json({
  success: true,
  orderId: orderRef.id,
  otpCode,
  vendorName,
  totalPaise: amount,
  estimatedReadyMinutes: 15,
  pickupMode: mode, // 🔥 IMPORTANT
});
    } catch (e) {
      console.error("VERIFY PAYMENT ERROR:", e);
      return res.status(500).json({ error: e.message });
    }
  });
});
// ============================================================
// BITEO AI SUPPORT
// ============================================================

exports.askSupportAI = onRequest((req, res) => {
  cors(req, res, async () => {
    try {

      const data =
        typeof req.body === "string"
          ? JSON.parse(req.body)
          : req.body;

      const { message, userId } = data;

      if (!message) {
        return res.status(400).json({
          success: false,
          message: "Message required",
        });
      }

      // 🔥 Gemini Init
      const genAI = new GoogleGenerativeAI(
        GEMINI_API_KEY.value()
      );

      const model = genAI.getGenerativeModel({
  model: "gemini-2.5-flash",
});

      // 🔥 Prompt
      const prompt = `
You are Biteo Support AI.

You help food delivery users.

Rules:
- Keep replies short.
- Be friendly.
- Help with orders, refunds, pickup, payments, offers.
- If issue sounds serious, say:
"Connecting you to a human support representative."

User Message:
${message}
`;

      console.log("🔥 CALLING GEMINI");

      const result =
        await model.generateContent(prompt);

      console.log(
        "🔥 GEMINI RESPONSE RECEIVED"
      );

      const reply =
        result.response.text();

      console.log(
        "🔥 FINAL REPLY:",
        reply
      );

      // 🔥 Save chat
      await db.collection("support_chats").add({
        user_id: userId ?? null,
        user_message: message,
        ai_reply: reply,
        created_at:
          admin.firestore.FieldValue.serverTimestamp(),
      });

      return res.json({
        success: true,
        reply,
      });

    } catch (e) {

      console.error("❌ SUPPORT AI ERROR:");
      console.error(e);

      return res.status(500).json({
        success: false,
        error: e.toString(),
      });
    }
  });
});
// ============================================================
// SEND NOTIFICATION TO ALL USERS
// ============================================================

exports.sendNotificationToAllUsers = onRequest((req, res) => {

  cors(req, res, async () => {

    try {

      const data =
        typeof req.body === "string"
          ? JSON.parse(req.body)
          : req.body;

      const {
        title,
        body,
      } = data;

      if (!title || !body) {

        return res.status(400).json({
          success: false,
          message: "Title and body required",
        });
      }

      // 🔥 Get all users
      const usersSnap =
        await db.collection("users").get();

      const tokens = [];

      usersSnap.forEach((doc) => {

        const user = doc.data();

        if (user.fcmToken) {
          tokens.push(user.fcmToken);
        }
      });

      if (tokens.length === 0) {

        return res.json({
          success: false,
          message: "No FCM tokens found",
        });
      }

      // 🔥 Send multicast notification
   const response =
  await admin.messaging()
    .sendEachForMulticast({

  notification: {
    title,
    body,
  },

  android: {
    priority: "high",
    notification: {
      sound: "default",
      channelId: "biteo_notifications",
    },
  },

  apns: {
    payload: {
      aps: {
        sound: "default",
      },
    },
  },

  tokens,
});

// 🔥 DEBUG EACH RESPONSE
response.responses.forEach((resp, idx) => {

  if (resp.success) {

    console.log(
      `✅ SUCCESS TOKEN ${idx}`
    );

  } else {

    console.log(
      `❌ FAILED TOKEN ${idx}`
    );

    console.log(
      resp.error
    );
  }
});

console.log(
  "🔥 FCM RESPONSE:",
  response.responses
);

      return res.json({

        success: true,
        totalTokens: tokens.length,
        successCount: response.successCount,
        failureCount: response.failureCount,
      });

    } catch (e) {

      console.error(
        "NOTIFICATION ERROR:",
        e
      );

      return res.status(500).json({
        success: false,
        error: e.toString(),
      });
    }
  });
});