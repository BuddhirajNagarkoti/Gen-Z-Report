# 📱 जियनजेड प्रतिवेदन २०८२ (Gen-Z Report 2025)

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-%23039BE5.svg?style=flat&logo=Firebase)
![Google Gemini](https://img.shields.io/badge/Gemini-8E75B2.svg?style=flat&logo=Google-Gemini&logoColor=white)

**Gen-Z Report 2082** is a state-of-the-art interactive digital publication platform designed to present the findings of the "High-Level Inquiry Commission's Technology and Research Branch" (उच्चस्तरीय जाँचबुझ आयोग). This report leverages the latest in mobile technology to provide an immersive, accessible, and AI-powered reading experience for the Gen-Z generation in Nepal.

---

## 🔥 Key features

### 📖 Immersive Reader (Citable Reading Mode)
*   **Distinct Typography**: Integrated with [Mukta Google Font](https://fonts.google.com/specimen/Mukta) for perfect Nepali legibility.
*   **Floating Navigation**: Quick-jump between 898+ pages with a modern, glassmorphic UI.
*   **Contextual Sidenotes**: Access deep-dive citations and references directly while reading.

### 📚 Streamlined Navigation
*   **Direct Entry**: New 'पूर्ण प्रतिवेदन' (Full Report) button to jump straight into research.
*   **Organized Access**: Logical flow from Preface to Table of Contents, then Chapter-by-Chapter reading.

### 🤖 Gemini AI Integration
*   **Interactive Chat Service**: Ask the report questions (via `GeminiChatService`) and get instant insights from the publication's content.
*   **Intelligent Summaries**: AI-driven breakdowns of complex socio-economic research data.

### 🎨 Premium UI/UX Experience
*   **Book-Cover Landing Screen**: Features a authentic paper-texture finish to merge the digital and physical reading worlds.
*   **Dynamic Theme Support**: Seamless switching between **Parchment Light Mode** and **Midnight OLED Dark Mode**.
*   **Responsive Layouts**: Optimized for both mobile phones and tablets.

---

## 🛠 Tech Stack

*   **Core**: [Flutter](https://flutter.dev/) (Channel Stable)
*   **Backend**: [Firebase](https://firebase.google.com/) (Authentication & Core Services)
*   **AI Engine**: [Google Gemini AI](https://ai.google.dev/)
*   **Navigation**: [GoRouter](https://pub.dev/packages/go_router) for deep-linking and state management.
*   **Design Tokens**: Material 3 based implementation with custom design-system overrides.

---

## 🚀 Getting Started

### Prerequisites

*   Flutter SDK (3.38.7 or later recommended)
*   Dart 3.x
*   A Firebase project with basic configuration

### Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/BuddhirajNagarkoti/Gen-Z-Report.git
    cd Gen-Z-Report
    ```

2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Run the application**:
    ```bash
    flutter run
    ```

---

## 📁 Project Structure

*   `lib/core/`: Foundation, themes, and service locators.
*   `lib/features/reader/`: The core reading experience and TOC management.
*   `lib/features/audiobook/`: Audio playback logic and interface.
*   `tests/`: Unit and widget tests to ensure data accuracy.
*   `texts/`: The high-quality Nepali textual data powering the report.

---

## ⚖️ License

Developed by **Buddhiraj Nagarkoti** as part of the **Higher Education and Technology & Research Branch** initiatives. All rights reserved 2082.

---

> "Technology is the bridge between research and progress." 🚀
