function showToast(message, type = "info", duration = 3000) {
  const existing = document.querySelector(".cm-toast");
  if (existing) existing.remove();

  const toast = document.createElement("div");
  toast.className = `cm-toast cm-toast-${type}`;
  toast.innerText = message + "      ";

  const progress = document.createElement("div");
  progress.className = "cm-toast-progress";
  toast.appendChild(progress);

  const closeBtn = document.createElement("button");
  closeBtn.className = "cm-toast-close";
  closeBtn.innerText = "×";
  closeBtn.onclick = () => {
    toast.style.opacity = "0";
    toast.style.transform = "translateY(20px)";
    setTimeout(() => toast.remove(), 400);
  };
  toast.appendChild(closeBtn);

  document.body.appendChild(toast);

  requestAnimationFrame(() => {
    toast.classList.add("show");
    progress.style.transition = `width ${duration}ms linear`;
    progress.style.width = "0%";
  });

  const timeout = setTimeout(() => {
    toast.style.opacity = "0";
    toast.style.transform = "translateY(20px)";
    setTimeout(() => toast.remove(), 400);
  }, duration);

  closeBtn.addEventListener("click", () => clearTimeout(timeout));
}

document.addEventListener("DOMContentLoaded", () => {
  const apiKeyInput = document.getElementById("apiKey");
  const saveButton = document.getElementById("saveButton");
  const deleteButton = document.getElementById("deleteButton");
  const formSection = document.getElementById("formSection");
  const statusSection = document.getElementById("statusSection");
  const showMaskToggle = document.getElementById("showMaskToggle");
  const blocklistInput = document.getElementById("blocklist");

  // Load API key
  chrome.storage.local.get("geminiApiKey", (data) => {
    if (data.geminiApiKey) {
      formSection.style.display = "none";
      statusSection.style.display = "block";
    }
  });

  // Load global settings
  chrome.storage.sync.get(["showMask", "blocklist"], (data) => {
    showMaskToggle.checked = data.showMask ?? true;
    blocklistInput.value = (data.blocklist || []).join("\n");
  });

  saveButton.addEventListener("click", () => {
    const apiKey = apiKeyInput.value.trim();
    if (!apiKey) {
      showToast("Please enter a valid API key.", "error");
      return;
    }

    showToast("Testing API Key...");

    chrome.runtime.sendMessage(
      { action: "testGeminiKey", apiKey: apiKey },
      (response) => {
        if (chrome.runtime.lastError) {
          showToast(
            "Extension error: " + chrome.runtime.lastError.message,
            "error"
          );
          return;
        }

        if (response?.error) {
          showToast("API Test Failed: " + response.error, "error");
          return;
        }

        if (response?.success) {
          chrome.storage.local.set({ geminiApiKey: apiKey }, () => {
            showToast("API Key saved successfully!");
            formSection.style.display = "none";
            statusSection.style.display = "block";
          });
        }
      }
    );
  });

  deleteButton.addEventListener("click", () => {
    chrome.storage.local.remove("geminiApiKey", () => {
      showToast("API Key deleted.");
      formSection.style.display = "block";
      statusSection.style.display = "none";
      apiKeyInput.value = "";
    });
  });
  getAndroidApp.addEventListener("click", () => {
    chrome.tabs.create({
      url: "https://github.com/Gupta-Aniket/corporate-mask/releases/download/android/Corporate.Mask.apk",
    });
  });

  showMaskToggle.addEventListener("change", () => {
    chrome.storage.sync.set({ showMask: showMaskToggle.checked });
  });

  blocklistInput.addEventListener("input", () => {
    const domains = blocklistInput.value
      .split("\n")
      .map((d) => d.trim())
      .filter(Boolean);
    chrome.storage.sync.set({ blocklist: domains });
  });
});
