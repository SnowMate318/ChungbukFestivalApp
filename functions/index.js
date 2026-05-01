const { initializeApp } = require("firebase-admin/app");
const { FieldValue, getFirestore } = require("firebase-admin/firestore");
const { defineSecret, defineString } = require("firebase-functions/params");
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");

initializeApp();

const db = getFirestore();
const smsEnabled = defineString("SMS_ENABLED", { default: "true" });
const smsApiUrl = defineString("SMS_API_URL", {
  default: "http://203.255.70.70:13000/sms/send",
});
const smsTestMode = defineString("SMS_TEST_MODE", { default: "N" });
const stampTourBaseUrl = defineString("STAMP_TOUR_BASE_URL", {
  default: "https://greenfestival-5320b.web.app",
});
const smsApiKey = defineSecret("SMS_API_KEY");

exports.sendSmsRequest = onDocumentCreated(
  {
    document: "smsRequests/{requestId}",
    region: "asia-northeast3",
    secrets: [smsApiKey],
  },
  async (event) => {
    if (!event.data) return;
    await processSmsRequest(event.params.requestId, event.data.data() || {});
  },
);

exports.retrySmsRequest = onDocumentUpdated(
  {
    document: "smsRequests/{requestId}",
    region: "asia-northeast3",
    secrets: [smsApiKey],
  },
  async (event) => {
    if (!event.data) return;

    const before = event.data.before.data() || {};
    const after = event.data.after.data() || {};
    if (before.status === "pending" || after.status !== "pending") {
      return;
    }

    await processSmsRequest(event.params.requestId, after);
  },
);

async function processSmsRequest(requestId, data) {
  const requestRef = db.collection("smsRequests").doc(requestId);
  const receiver = String(data.receiver || "").trim();
  const uid = String(data.uid || "").trim();
  const message = uid
    ? buildWelcomeMessage(uid, stampTourBaseUrl.value())
    : String(data.message || "").trim();
  const testMode = resolveTestMode(data.testMode);

  if (!isEnabled(smsEnabled.value())) {
    await requestRef.update({
      status: "skipped",
      error: "SMS_ENABLED is false",
      updatedAt: FieldValue.serverTimestamp(),
    });
    return;
  }

  const apiUrl = smsApiUrl.value().trim();
  const apiKey = smsApiKey.value().trim();

  if (!receiver || !message) {
    await requestRef.update({
      status: "failed",
      error: "receiver and message are required",
      updatedAt: FieldValue.serverTimestamp(),
    });
    return;
  }

  if (!apiUrl || !apiKey) {
    await requestRef.update({
      status: "skipped",
      error: "SMS_API_URL or SMS_API_KEY is not configured",
      updatedAt: FieldValue.serverTimestamp(),
    });
    return;
  }

  try {
    await requestRef.update({
      status: "sending",
      error: null,
      message,
      testMode,
      attemptCount: FieldValue.increment(1),
      updatedAt: FieldValue.serverTimestamp(),
    });

    const response = await fetch(apiUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "X-API-KEY": apiKey,
      },
      body: JSON.stringify({
        receiver,
        message,
        testMode,
      }),
    });

    const responseText = await response.text();
    const responsePayload = parseJsonOrNull(responseText);
    if (!response.ok) {
      throw new Error(
        `SMS API failed with ${response.status}: ${responseText}`,
      );
    }

    await requestRef.update({
      status: "sent",
      provider: "json_sms_api",
      response: responsePayload || null,
      responseBody: responsePayload ? null : responseText || null,
      sentAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  } catch (error) {
    await requestRef.update({
      status: "failed",
      error: error.message || String(error),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
}

function buildWelcomeMessage(uid, baseUrl) {
  const normalizedBaseUrl = String(baseUrl || "").replace(/\/+$/, "");
  return (
    "안녕하세요\n" +
    "2026 청주가 그린 GREEN 페스티벌 참여 안내입니다.\n\n" +
    "아래 링크를 통해 축제를 즐겨주세요\n\n" +
    "스탬프 투어\n" +
    `${normalizedBaseUrl}/stamp-tour/${uid}\n\n` +
    "오픈채팅방 접속\n" +
    `https://open.kakao.com/o/g2j30usi \n\n` +
    "축제장에서 즐거운 시간 보내세요.\n" +
    "감사합니다.\n"
  );
}

function resolveTestMode(requestTestMode) {
  if (requestTestMode === true) {
    return "Y";
  }
  if (requestTestMode === false) {
    return "N";
  }
  if (typeof requestTestMode === "string") {
    const normalized = requestTestMode.trim();
    if (normalized) {
      const upper = normalized.toUpperCase();
      if (upper === "TRUE") {
        return "Y";
      }
      if (upper === "FALSE") {
        return "N";
      }
      return normalized;
    }
  }
  return smsTestMode.value().trim() || "N";
}

function isEnabled(value) {
  return ["1", "true", "y", "yes", "on"].includes(
    String(value || "").trim().toLowerCase(),
  );
}

function parseJsonOrNull(text) {
  if (!text) {
    return null;
  }
  try {
    return JSON.parse(text);
  } catch (_error) {
    return null;
  }
}
