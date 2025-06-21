# Corporate Mask

> **Corporate Mask - Instant Professional Rewrites**

Turn your raw thoughts into polished corporate messages. Enter your text and Corporate Mask instantly generates 4 tone variations — Formal, Semi-Formal, Casual, and Brutally Honest — all corporate-safe. Powered by Gemini AI.

---

## 📦 Repository Structure

```
.
├── app
│   └── corporate_mask
│       ├── README.md
│       ├── analysis_options.yaml
│       ├── android
│       ├── assets
│       ├── build
│       ├── corporate_mask.iml
│       ├── ios
│       ├── lib
│       ├── pubspec.lock
│       └── pubspec.yaml
│
├── extension
│   ├── assets
│   │   ├── icon128.png
│   │   ├── icon16.png
│   │   └── icon48.png
│   ├── background.js
│   ├── content.js
│   ├── fileContext.txt
│   ├── file_context.py
│   ├── manifest.json
│   ├── options.html
│   ├── options.js
│   ├── overlay.js
│   └── style.css
```

---

# 🔥 Project Details

This repository contains two parts:

### 1️⃣ `app/corporate_mask/` — Flutter Mobile App

- Fully native Android/iOS app
- Built with Flutter using simple `setState()` management
- Dark mode, iOS-like Cupertino design
- Uses Google Gemini API
- Local storage of API key using `shared_preferences`

### 2️⃣ `extension/` — Original Browser Extension

- Chrome extension version of Corporate Mask
- Built with HTML, CSS, JavaScript
- Same core functionality via Gemini API
- Floating button UI for in-browser text rewriting

---

# 🚀 Flutter App: Build & Run

### 1️⃣ Navigate to Flutter app directory

```bash
cd app/corporate_mask
```

### 2️⃣ Install dependencies

```bash
flutter pub get
```

### 3️⃣ Run app (emulator or device)

```bash
flutter run
```

### 4️⃣ Build APK for release

```bash
flutter build apk --release
```

### 5️⃣ Build iOS (on macOS)

```bash
flutter build ios
```

---

# 🖥 Extension: Load Unpacked

### 1️⃣ Navigate to `extension/` directory

```bash
cd extension
```

### 2️⃣ In Chrome:

- Go to `chrome://extensions/`
- Enable **Developer Mode**
- Click **Load Unpacked**
- Select the `extension/` folder

The Corporate Mask extension will load into Chrome locally.

---

# 🔑 Gemini API Key Setup

- Go to: https://aistudio.google.com/app/apikey
- Generate your Gemini API Key (ensure billing is active if needed)
- Paste this key inside the app when prompted

---

# 📦 GitHub Releases

Inside GitHub Releases, you will find:

- `corporate_mask_flutter.apk` — Pre-built Android APK
- `corporate_mask_extension.zip` — Browser extension as zipped archive

---

# 🔧 Flutter Dependencies

- `flutter`
- `shared_preferences`
- `http`
- `cupertino_icons`

---

# 👨‍💻 Author

- Developed by Aniket

---

# 📄 License

See LICENSE file for full license terms. (MIT License)

---

**Note:** The Flutter app is a complete mobile rebuild of the original browser extension. All browser-specific floating UI logic has been redesigned for mobile-first experience.
