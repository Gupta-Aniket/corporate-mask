document.addEventListener("focusin", (e) => {
  const el = e.target;
  if (el.tagName === "TEXTAREA" || el.isContentEditable) {
    lastFocusedEditable = el;
  }
});
let lastFocusedEditable = null;
function showToast(message, type = "info", duration = 3000) {
  const existing = document.querySelector(".cm-toast");
  if (existing) existing.remove();

  const toast = document.createElement("div");
  toast.className = `cm-toast cm-toast-${type}`;
  toast.innerText = message + "      ";

  // Progress bar
  const progress = document.createElement("div");
  progress.className = "cm-toast-progress";
  toast.appendChild(progress);

  // Close button
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

  // Animate in
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

  // If closed manually, cancel auto timeout
  closeBtn.addEventListener("click", () => clearTimeout(timeout));
}

function injectGlobalButton() {
  if (document.querySelector("#corporate-mask-global-container")) return;

  const container = document.createElement("div");
  container.id = "corporate-mask-global-container";
  container.style.position = "fixed";
  container.style.bottom = "20px";
  container.style.right = "20px";
  container.style.zIndex = "999999";
  container.style.width = "60px";
  container.style.height = "60px";
  container.style.display = "flex";
  container.style.alignItems = "center";
  container.style.justifyContent = "center";
  container.style.cursor = "grab";
  container.style.transition = "all 0.4s ease";

  const button = document.createElement("button");
  button.id = "corporate-mask-global-btn";
  button.innerText = "🎭";
  button.title = "Corporate Mask";
  button.type = "button";

  button.style.width = "60px";
  button.style.height = "60px";
  button.style.border = "none";
  button.style.background = "#fff";
  button.style.borderRadius = "50%";
  button.style.boxShadow = "0 4px 8px rgba(0,0,0,0.2)";
  button.style.cursor = "pointer";
  button.style.fontSize = "28px";
  button.style.transition = "all 0.3s ease";

  const closeBtn = document.createElement("div");
  closeBtn.innerText = "x";
  closeBtn.title = "Hide";
  closeBtn.style.position = "absolute";
  closeBtn.style.top = "-10px";
  closeBtn.style.right = "-10px";
  closeBtn.style.width = "24px";
  closeBtn.style.height = "24px";
  closeBtn.style.color = "#fff";
  closeBtn.style.fontSize = "16px";
  closeBtn.style.fontWeight = "bold";
  closeBtn.style.borderRadius = "50%";
  closeBtn.style.display = "none";
  closeBtn.style.alignItems = "center";
  closeBtn.style.justifyContent = "center";
  closeBtn.style.cursor = "pointer";

  container.addEventListener("mouseenter", () => {
    closeBtn.style.display = "flex";
  });
  container.addEventListener("mouseleave", () => {
    closeBtn.style.display = "none";
  });

  button.addEventListener("click", () => {
    if (lastFocusedEditable) {
      createOverlay(lastFocusedEditable);
    } else {
      showToast("Please focus on a text field first.");
    }
  });

  closeBtn.addEventListener("click", () => {
    hideButton();
    chrome.storage.sync.set({ showMask: false });
    showToast("👋 Corporate Mask is now disabled.");
  });

  // Visibility control functions:
  function hideButton() {
    container.style.transform = "scale(0)";
    container.style.opacity = "0";
    container.style.pointerEvents = "none";
  }

  function showButton() {
    container.style.transform = "scale(1)";
    container.style.opacity = "1";
    container.style.pointerEvents = "auto";
  }

  container.hideButton = hideButton;
  container.showButton = showButton;

  container.appendChild(button);
  container.appendChild(closeBtn);
  document.body.appendChild(container);

  makeFloatingDraggable(container);
}

// Drag logic (unchanged)
function makeFloatingDraggable(element) {
  let isDragging = false;
  let startX, startY, initialX, initialY;

  element.addEventListener("mousedown", (e) => {
    if (e.target === element || e.target === element.firstChild) {
      isDragging = true;
      startX = e.clientX;
      startY = e.clientY;
      const rect = element.getBoundingClientRect();
      initialX = rect.left;
      initialY = rect.top;
      element.style.cursor = "grabbing";
      e.preventDefault();
    }
  });

  document.addEventListener("mousemove", (e) => {
    if (!isDragging) return;
    const dx = e.clientX - startX;
    const dy = e.clientY - startY;
    element.style.left = `${initialX + dx}px`;
    element.style.top = `${initialY + dy}px`;
    element.style.right = "auto";
    element.style.bottom = "auto";
  });

  document.addEventListener("mouseup", () => {
    if (isDragging) {
      isDragging = false;
      element.style.cursor = "grab";
    }
  });
}

injectGlobalButton();

// Main observer logic with chrome.storage toggle:

function updateButtonVisibility() {
  const container = document.querySelector("#corporate-mask-global-container");
  if (!container) return;

  chrome.storage.sync.get(["showMask", "blocklist"], (data) => {
    const showMask = data.showMask ?? true;
    const blocklist = data.blocklist || [];
    blocklist.push("canva.com");

    const hostname = window.location.hostname;

    const blocked = blocklist.some((domain) => hostname.includes(domain));

    if (!showMask || blocked) {
      container.hideButton();
    } else {
      container.showButton();
    }
  });
}

document.addEventListener("DOMContentLoaded", () => {
  injectGlobalButton();
  updateButtonVisibility();
});

chrome.storage.onChanged.addListener((changes, area) => {
  if (area === "sync" && (changes.showMask || changes.blocklist)) {
    updateButtonVisibility();
  }
});
