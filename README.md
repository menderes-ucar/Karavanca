# Karavanca 🚐✨ - Premium C2C Marketplace & Travel Discovery Platform

Karavanca is a comprehensive, production-ready mobile application built with **Flutter** and **Dart**, specifically designed for camping and caravan enthusiasts. It serves as a dual-purpose platform combining a high-end peer-to-peer (P2P) marketplace for caravan rentals, sales, and camping gear with a robust, location-based travel discovery engine.

---
---
## 📸 UI/UX Design & Screenshots



| Main Screen | Caravan Listings | User Profile & Credits |

| :---: | :---: | :---: |

| <img width="738" height="1600" alt="karavanca1" src="https://github.com/user-attachments/assets/e822d3c8-1504-4e1f-82de-9f35cdfafa32" /> |<img width="740" height="1600" alt="karavanca2" src="https://github.com/user-attachments/assets/abcd5def-cf3d-40e3-9c91-c8da9480a44c" /> | <img width="388" height="844" alt="karavanca4" src="https://github.com/user-attachments/assets/982484cc-d3bc-445f-9dd6-6ebb18c7a908" /> |



| Map & Explore | Extra Interface |

| :---: | :---: |

|<img width="396" height="844" alt="karavanca3" src="https://github.com/user-attachments/assets/0497a57c-ef6a-4edf-b9c6-56464d0eb3ee" /> | <img width="393" height="847" alt="karavanca5" src="https://github.com/user-attachments/assets/334f5abf-b6e8-4f33-a6e6-fd9bd71e57dc" /> |



---



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
