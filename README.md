# Karavanca 🚐✨ - Premium C2C Marketplace & Travel Discovery Platform

Karavanca is a comprehensive, production-ready mobile application built with **Flutter** and **Dart**, specifically designed for camping and caravan enthusiasts. It serves as a dual-purpose platform combining a high-end peer-to-peer (P2P) marketplace for caravan rentals, sales, and camping gear with a robust, location-based travel discovery engine.

---

## 📸 UI/UX Design & Screenshots

| Main Screen | Caravan Listings | User Profile & Credits |
| :---: | :---: | :---: |
| <img src="https://raw.githubusercontent.com/menderes-ucar/Karavanca/main/karavanca5.jpeg" width="250"> | <img src="https://raw.githubusercontent.com/menderes-ucar/Karavanca/main/karavanca2.jpeg" width="250"> | <img src="https://raw.githubusercontent.com/menderes-ucar/Karavanca/main/karavanca4.jpeg" width="250"> |

*Note: Developed with a mobile-first philosophy, adhering strictly to modern premium design principles, responsive layouts, and dynamic theme scaling.*

---

## 🛠️ Technical Architecture & Key Features

*   **Hybrid Backend Infrastructure:** Engineered a scalable hybrid backend system utilizing **Supabase** (PostgreSQL) for structured relational data management, user advertisements, and market transactions, paired with **Cloud Firestore** for high-frequency, real-time data streaming.
*   **Real-Time Peer-to-Peer (P2P) Chat:** Implemented an optimized instant messaging engine allowing seamless, real-time negotiation between buyers and sellers within the marketplace.
*   **Geospatial & Location-Based Services (LBS):** Integrated advanced mapping and routing APIs enabling users to discover, filter, and navigate to verified camping zones across Turkey.
*   **Secure Push Notification Pipeline:** Utilized **Firebase Cloud Messaging (FCM)** to architect a background/foreground notification pipeline for instant user alerts regarding messages and listing status changes.
*   **Clean State Management:** Powered entirely by the **Provider** framework to enforce a strict separation of concerns, optimize widget rebuilding lifecycles, and ensure a fluid 60 FPS performance.
*   **Monetization & Content Moderation Infrastructure:** Designed custom back-office and profile logic featuring an *Ad Credit System (İlan Kredisi)*, *Image Constraints (Foto Limit)*, and manual admin verification pipelines to ensure platform security and monetization control.

---

## 💻 Tech Stack & Libraries Used

*   **Frontend:** Flutter SDK (Dart)
*   **State Management:** Provider
*   **Database & Backend:** Supabase (PostgreSQL), Google Firebase Suite (Firestore)
*   **Notifications:** Firebase Cloud Messaging (FCM)
*   **Utilities:** Geolocation / Geocoding APIs, Shared Preferences, Image Picker

---

## 🚀 Getting Started

### Prerequisites
Before running the project, ensure you have the Flutter SDK configured on your machine and access to your Supabase/Firebase credentials.

### Installation

1. Clone the repository:
```bash
   git clone [https://github.com/menderes-ucar/Karavanca.git](https://github.com/menderes-ucar/Karavanca.git)
