# GateKeeper 🛡️

A lightweight, real-time visitor management system built with Flutter and Firebase.

## 👥 Team
* Premapriya D | Chaithanya | Shaswath K.G

## 🎯 The Problem
Gated communities use paper logs that are:
1. **Unreadable:** Hard to track who is inside.
2. **Insecure:** Personal phone numbers are visible to everyone.
3. **Slow:** No way to verify a visitor without calling the resident manually.

## 🚀 Our Solution
A 3-screen app ecosystem that digitizes the gate:

### 1. Guard App (The Entry)
* Simple form to record Name, Phone, and Flat Number.
* Real-time "Approval Status" indicator.
* Digital "Check-out" list.

### 2. Resident App (The Control)
* Instant Push Notifications for new visitors.
* One-tap Approve/Deny buttons.
* History of past visitors to their specific flat.

### 3. Admin (The Record)
* A simple Firestore-backed dashboard to view all entry/exit logs with timestamps.

## ⚙️ Tech Stack
* **UI:** Flutter (Dart)
* **Database:** Cloud Firestore (Real-time sync)
* **Auth:** Firebase Phone Auth (OTP for secure login)
* **Alerts:** Firebase Cloud Messaging (FCM)