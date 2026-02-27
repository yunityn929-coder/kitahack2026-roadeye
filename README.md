# 🚧 RoadEye OS — Hazard Intelligence Dashboard

> A real-time road hazard monitoring platform built with Flutter Web, Firebase, and Google Maps. Powered by Gemini 1.5 Flash AI for automated pothole detection and verification.

---

## 📸 Overview

![Dashboard Overview](screenshots/dashboard.png)

RoadEye OS is the web-based admin dashboard of the RoadEye platform. It listens to a live Firestore stream, plots detected hazards on an interactive map the moment they arrive, and gives admins the tools to manage, resolve, and report on road hazards — all in real time.

A mobile scanning app captures road photos on the go. Each photo is automatically verified by **Gemini 1.5 Flash** via a Cloud Functions pipeline, which scores confidence, determines severity, and writes the result directly to Firestore — where the dashboard picks it up instantly.

---

## ✨ Features

### 🗺️ Live Hazard Map

- Real-time Google Maps integration with custom SVG pin markers
- Markers colour-coded by severity — **HIGH** (red), **MEDIUM** (orange), **LOW** (amber), **RESOLVED** (green)
- Click any marker to view a popup with image, coordinates, severity badge, and a **Mark as Repaired** button
- Severity filter bar — toggle HIGH / MEDIUM / LOW / RESOLVED markers on/off with live counts

### 📋 Active Potholes List

![Active Potholes List](screenshots/active_pothole_history.png)

- Paginated list of all unresolved hazards
- Sortable by confidence score and severity
- One-click resolve from the list view

### 🕓 Repaired History

![Repaired History](screenshots/repaired_history.png)

- Full log of all resolved hazards with animated cards
- Shows original severity, confidence score, coordinates, and detection image

### 📊 Analytics Dashboard

![Analytics Dashboard](screenshots/analytics.png)

- Live KPI cards — Total Hazards, Active, Resolved, Resolution Rate
- Donut chart — Status breakdown (Resolved vs Active)
- Severity distribution bar chart — HIGH / MEDIUM / LOW
- Circular resolution progress ring
- Severity × Status matrix cross-tab table

### 📥 CSV Export

- One-click download of the full hazards dataset
- Includes ID, detected by, coordinates, confidence %, severity, and status

### 👤 Profile & Account

![Profile & Reset Password](screenshots/reset_password.png)

- Profile modal showing logged-in admin email and role badge
- Password reset via Firebase Auth email link — sent directly from the dashboard

### 🔐 Authentication

| Login                              | Register                                 |
| ---------------------------------- | ---------------------------------------- |
| ![Login Page](screenshots/login.png) | ![Register Page](screenshots/register.png) |

- Firebase Auth email/password login and signup
- Admin-only account creation
- Secure logout with session clear

---


## 🛠️ Tech Stack

| Layer        | Technology                            |
| ------------ | ------------------------------------- |
| Frontend     | Flutter Web                           |
| Database     | Cloud Firestore                       |
| Auth         | Firebase Authentication               |
| Storage      | Firebase Storage                      |
| Maps         | Google Maps JavaScript API            |
| AI Detection | Gemini 1.5 Flash (Vertex AI)          |
| Backend      | Firebase Cloud Functions (Node.js 20) |
| Hosting      | Firebase Hosting*(recommended)*       |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) `>=3.0.0`
- [Node.js](https://nodejs.org/) `>=20`
- A [Firebase project](https://console.firebase.google.com/) with the following enabled:
  - Authentication (Email/Password)
  - Cloud Firestore
  - Firebase Storage
  - Cloud Functions
- A [Google Maps API key](https://developers.google.com/maps/documentation/javascript/get-api-key) with **Maps JavaScript API** enabled
- Vertex AI API enabled in Google Cloud

---

### 1. Clone the repository

```bash
git clone https://github.com/your-username/roadeye-dashboard.git
cd roadeye-dashboard
```

### 2. Install Flutter dependencies

```bash
flutter pub get
```

### 3. Configure Firebase (Dashboard)

Replace the placeholder values in `lib/firebase_options.dart` and `lib/main.dart`:

```dart
await Firebase.initializeApp(
  options: const FirebaseOptions(
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_PROJECT.firebaseapp.com",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_PROJECT.appspot.com",
    messagingSenderId: "YOUR_SENDER_ID",
    appId: "YOUR_APP_ID",
  ),
);
```

### 4. Add your Google Maps API key

In `web/index.html`, add inside `<head>`:

```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_GOOGLE_MAPS_API_KEY"></script>
```

### 5. Enable Vertex AI

```bash
gcloud services enable aiplatform.googleapis.com --project=YOUR_PROJECT_ID
```

Then in **Google Cloud Console → IAM**, find your service account (`YOUR_PROJECT@appspot.gserviceaccount.com`) and add the **Vertex AI User** role.

### 6. Deploy Cloud Functions

```bash
cd functions
npm install
npm run deploy
```

### 7. Run the dashboard

```bash
flutter run -d chrome
```

---

## 🗄️ Firestore Data Structure

The dashboard reads from a single collection: `hazards_raw`

### Document schema

| Field            | Type          | Description                                                              |
| ---------------- | ------------- | ------------------------------------------------------------------------ |
| `lat`          | `number`    | Latitude of detected hazard                                              |
| `lng`          | `number`    | Longitude of detected hazard                                             |
| `confidence`   | `number`    | Gemini AI confidence score `0.0 – 1.0`                                |
| `imageUrl`     | `string`    | Firebase Storage URL of the detection image                              |
| `detectedBy`   | `string`    | Device/vehicle ID that submitted the hazard                              |
| `status`       | `string`    | `PENDING` · `ACTIVE` · `RESOLVED` · `ERROR` · `UNVERIFIED` |
| `severity`     | `string`    | `LOW` · `MEDIUM` · `HIGH` (set by Gemini)                        |
| `isPothole`    | `bool`      | Gemini's binary classification result                                    |
| `description`  | `string`    | Gemini's one-sentence description of the hazard                          |
| `createdAt`    | `timestamp` | When the hazard was submitted                                            |
| `verifiedAt`   | `timestamp` | When Gemini completed verification                                       |
| `geminiRaw`    | `string`    | Raw Gemini JSON response (for debugging)                                 |
| `errorMessage` | `string?`   | Populated if `status = ERROR`                                          |

### Severity mapping

| Confidence Score | Severity  |
| ---------------- | --------- |
| `≥ 0.8`       | 🔴 HIGH   |
| `≥ 0.5`       | 🟠 MEDIUM |
| `< 0.5`        | 🟡 LOW    |

### Example document

```json
{
  "lat": 3.139,
  "lng": 101.6869,
  "confidence": 0.87,
  "imageUrl": "https://firebasestorage.googleapis.com/...",
  "detectedBy": "VEHICLE_001",
  "status": "ACTIVE",
  "severity": "HIGH",
  "isPothole": true,
  "description": "Large pothole covering most of the left lane, approximately 40cm wide.",
  "createdAt": "2024-01-23T10:30:00Z",
  "verifiedAt": "2024-01-23T10:30:04Z",
  "geminiRaw": "{\"isPothole\":true,\"confidence\":0.87,\"severity\":\"HIGH\",\"description\":\"...\"}"
}
```

---
