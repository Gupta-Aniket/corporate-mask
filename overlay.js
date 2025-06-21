let cachedResponse = null;

function createOverlay(targetEditable) {
  if (document.querySelector(".corporate-mask-overlay")) return;

  const overlay = document.createElement("div");
  overlay.className = "corporate-mask-overlay";

  let currentText =
    targetEditable.tagName === "TEXTAREA"
      ? targetEditable.value
      : targetEditable.innerText;

  overlay.innerHTML = `
<div class="cm-overlay-container">
    <div class="cm-overlay-header">
      <div class="cm-overlay-logo">😠🎭 Corporate Mask</div>
      <button class="cm-overlay-close">&times;</button>
    </div>
    <textarea class="cm-overlay-textarea">${currentText}</textarea>
    <div class="cm-overlay-buttons">
      <button class="cm-convertBtn" id="generateBtn">Apply Mask</button>
      <span id="spinner" style="display:none;"></span>
    </div>
    <div class="cm-mode-buttons" style="display:none; grid-template-columns: repeat(1, 1fr); gap: 8px; margin-top: 12px;">
      <div class="cm-modeBtn" data-mode="formal">
        <div class="mode-icon">🎯</div>
        <div class="mode-content">
          <div class="mode-title">Formal</div>
          <div class="mode-description">Professional and polite tone for seniors.</div>
        </div>
      </div>
      <div class="cm-modeBtn" data-mode="semi_formal">
        <div class="mode-icon">💬</div>
        <div class="mode-content">
          <div class="mode-title">Semi-Formal</div>
          <div class="mode-description">Slightly more formal tone for colleagues.</div>
        </div>
      </div>
      <div class="cm-modeBtn" data-mode="casual">
        <div class="mode-icon">😉</div>
        <div class="mode-content">
          <div class="mode-title">Casual</div>
          <div class="mode-description">Casual and friendly tone for colleagues.</div>
        </div>
      </div>
      <div class="cm-modeBtn" data-mode="f_it">
        <div class="mode-icon">🤬</div>
        <div class="mode-content">
          <div class="mode-title">F it</div>
          <div class="mode-description">Brutally honest, still professional.</div>
        </div>
      </div>

    </div>
</div>
  `;

  document.body.appendChild(overlay);

  // Initial positioning (bottom-right)
  overlay.style.position = "fixed";
  overlay.style.bottom = "90px";
  overlay.style.right = "20px";
  overlay.style.left = "auto";
  overlay.style.top = "auto";
  overlay.style.transform = "none";
  overlay.style.zIndex = "10005";
  overlay.style.minWidth = "400px";
  overlay.style.maxWidth = "90vw";

  overlay
    .querySelector(".cm-overlay-close")
    .addEventListener("click", () => overlay.remove());

  overlay.querySelector("#generateBtn").addEventListener("click", () => {
    const userInput = overlay
      .querySelector(".cm-overlay-textarea")
      .value.trim();
    if (!userInput) {
      showToast("Please enter some text.");
      return;
    }

    const generateBtn = overlay.querySelector("#generateBtn");
    const modeButtons = overlay.querySelector(".cm-mode-buttons");
    const spinner = overlay.querySelector("#spinner");

    generateBtn.disabled = true;
    generateBtn.innerText = "Generating...";
    spinner.innerHTML = '<div class="cm-spinner"></div>';
    spinner.style.display = "inline-block";
    modeButtons.style.display = "none";

    chrome.runtime.sendMessage(
      { action: "callGeminiAllModes", userInput: userInput },
      (response) => {
        generateBtn.innerText = "Regenerate";
        generateBtn.disabled = false;
        spinner.style.display = "none";

        if (chrome.runtime.lastError) {
          showToast("Extension error: " + chrome.runtime.lastError.message);
          overlay.remove();
          return;
        }
        if (response?.error) {
          showToast("😢 Something went wrong:\n\n" + response.error);
          overlay.remove();
          return;
        }
        if (!response?.result) {
          showToast("No content was returned by Gemini. Try again later.");
          overlay.remove();
          return;
        }

        cachedResponse = response.result;
        modeButtons.style.display = "grid";
      }
    );
  });

  overlay.querySelectorAll(".cm-modeBtn").forEach((btn) => {
    btn.addEventListener("click", () => {
      const mode = btn.dataset.mode;
      if (!cachedResponse) return;
      const newText = cachedResponse[mode];
      if (targetEditable.tagName === "TEXTAREA") {
        targetEditable.value = newText;
      } else {
        targetEditable.innerText = newText;
      }
    });
  });

  makeOverlayDraggable(overlay);
}

function makeOverlayDraggable(el) {
  let posX = 0,
    posY = 0,
    startX = 0,
    startY = 0;
  const header = el.querySelector(".cm-overlay-header");
  header.style.cursor = "move";
  header.onmousedown = dragMouseDown;

  function dragMouseDown(e) {
    e.preventDefault();

    // Before dragging, convert fixed bottom/right into top/left for free movement
    if (el.style.position === "fixed") {
      const rect = el.getBoundingClientRect();
      el.style.top = `${rect.top}px`;
      el.style.left = `${rect.left}px`;
      el.style.bottom = "auto";
      el.style.right = "auto";
    }

    startX = e.clientX;
    startY = e.clientY;
    document.onmouseup = closeDrag;
    document.onmousemove = elementDrag;
  }

  function elementDrag(e) {
    e.preventDefault();
    posX = startX - e.clientX;
    posY = startY - e.clientY;
    startX = e.clientX;
    startY = e.clientY;
    el.style.top = el.offsetTop - posY + "px";
    el.style.left = el.offsetLeft - posX + "px";
  }

  function closeDrag() {
    document.onmouseup = null;
    document.onmousemove = null;
  }
}
