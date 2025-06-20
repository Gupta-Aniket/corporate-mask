chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === "callGeminiAllModes") {
    handleGeminiCall(request.userInput)
      .then((result) => {
        sendResponse(result);
      })
      .catch((err) => {
        console.error("[BG] Unhandled error:", err);
        sendResponse({ error: formatFriendlyError(err) });
      });

    return true; // Needed for async response
  }
  if (request.action === "testGeminiKey") {
    testGeminiKey(request.apiKey)
      .then((result) => {
        sendResponse(result);
      })
      .catch((err) => {
        console.error("[BG] Test Key Error:", err);
        sendResponse({ error: err.message });
      });

    return true;
  }
});
async function testGeminiKey(apiKey) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`;

  const dummyPrompt =
    "Test message: Please return a short success confirmation.";

  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ parts: [{ text: dummyPrompt }] }],
    }),
  });

  if (!res.ok) {
    throw new Error(`API responded with status ${res.status}`);
  }

  const result = await res.json();
  console.log("[BG] Gemini test response:", result);

  // Simplest check: did we get any candidates at all
  if (result?.candidates?.length > 0) {
    return { success: true };
  } else {
    throw new Error("Gemini API returned no candidates.");
  }
}

function formatFriendlyError(err) {
  if (typeof err === "string") return err;

  const message = err?.message || "Unknown error occurred.";
  if (message.includes("429"))
    return "Daily quota limit exceeded. Try again tomorrow.";
  if (message.includes("403"))
    return "Access denied. Check your API key billing settings.";
  if (message.includes("401"))
    return "Unauthorized. Your API key is invalid or expired.";
  if (message.includes("JSON"))
    return "Received an invalid response from Gemini.";

  return "Unexpected error: " + message;
}

async function handleGeminiCall(userInput) {
  const data = await chrome.storage.local.get("geminiApiKey");
  const apiKey = data.geminiApiKey;

  if (!apiKey) {
    throw new Error("API key not set.");
  }

  const prompt = buildPrompt(userInput);
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`;

  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
    }),
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`HTTP ${res.status}: ${errText}`);
  }

  const result = await res.json();
  const raw = result?.candidates?.[0]?.content?.parts?.[0]?.text;

  if (!raw) throw new Error("No content returned from Gemini.");

  const cleaned = raw
    .replace(/^\s*```json\s*/i, "")
    .replace(/```$/, "")
    .trim();

  try {
    const json = JSON.parse(cleaned);
    return { result: json };
  } catch (err) {
    throw new Error("Failed to parse AI response: " + err.message);
  }
}

function buildPrompt(userInput) {
  return `
Given the following message, generate 4 variants:
- "formal": corporate pleasing, highly professional tone polite for senior level managers etc . 
- "semi_formal": corporate pleasing Semi-formal, polite for colleagues.
- "casual": corporate plesing Friendly casual internal tone.
- "f_it": Brutally honest but still corporate-safe try to be pleasing.

Output STRICT valid JSON with keys: "formal", "semi_formal", "casual", "f_it".
Do not include any markdown, explanations or commentary. Just output raw valid JSON.

Here is the message:
"${userInput}"
`;
}
