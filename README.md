
# GateKeeper 🛡️

A lightweight, real-time visitor management system built with Flutter and Firebase.

## 👥 Team & Responsibilities

| Member | Role | Responsibilities |
|--------|------|------------------|
| **Premapriya D** | Backend Developer | Firebase services, Firestore operations, State management |
| **Chaithanya** | Frontend Developer | UI screens, Widgets, Navigation, User experience |
| **Shaswath K.G** | Full Stack Developer | Data models, Core utilities, Theme, App integration |

## 🎯 The Problem
Gated communities use paper logs that are:
1. **Unreadable:** Hard to track who is inside.
2. **Insecure:** Personal phone numbers are visible to everyone.
3. **Slow:** No way to verify a visitor without calling the resident manually.

## 🚀 Our Solution
A 3-screen app ecosystem that digitizes the gate:

### 1. Guard App (The Entry)
Simple form to record Name, Phone, and Flat Number.
Real-time "Approval Status" indicator.
Digital "Check-out" list.

### 2. Resident App (The Control)
Instant Push Notifications for new visitors.
One-tap Approve/Deny buttons.
History of past visitors to their specific flat.

### 3. Admin (The Record)
A simple Firestore-backed dashboard to view all entry/exit logs with timestamps.

## ⚙️ Tech Stack
**UI:** Flutter (Dart)
**Database:** Cloud Firestore (Real-time sync)
**Auth:** Firebase Phone Auth (OTP for secure login)
**Alerts:** Firebase Cloud Messaging (FCM)

---

## 📁 Project Structure

lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration (auto-generated)
│
├── core/                     # Core utilities shared across the app
│   ├── constants/            # App-wide constants (colors, strings, enums)
│   ├── theme/                # App theme configuration (colors, text styles)
│   └── routes/               # Navigation route definitions
│
├── models/                   # Data models for Firestore documents
│   ├── user_model.dart       # User data (guard/resident/admin)
│   ├── visitor_model.dart    # Visitor entry data
│   └── flat_model.dart       # Flat/apartment data
│
├── services/                 # Firebase service layer
│   ├── auth_service.dart     # Firebase Phone Authentication
│   ├── user_service.dart     # User CRUD operations (Firestore)
│   ├── visitor_service.dart  # Visitor CRUD operations (Firestore)
│   └── fcm_service.dart      # Push notification handling
│
├── providers/                # State management (Provider)
│   ├── auth_provider.dart    # Authentication state
│   └── visitor_provider.dart # Visitor data state
│
├── screens/                  # UI screens organized by user role
│   ├── auth/                 # Authentication screens
│   │   ├── phone_input_screen.dart      # Phone number entry
│   │   ├── otp_verification_screen.dart # OTP verification
│   │   └── role_selection_screen.dart   # Role selection (new users)
│   │
│   ├── guard/                # Guard app screens
│   │   ├── guard_home_screen.dart       # Guard dashboard
│   │   └── add_visitor_screen.dart      # Add new visitor form
│   │
│   ├── resident/             # Resident app screens
│   │   └── resident_home_screen.dart    # Approve/deny visitors
│   │
│   └── admin/                # Admin app screens
│       └── admin_home_screen.dart       # View all logs
│
└── widgets/                  # Reusable UI components
    └── visitor_card.dart     # Visitor info card widget

## 📄 File Descriptions

### Core
| File | Purpose |
|------|---------|
| core/constants/ | App constants like user roles, visitor statuses, Firestore collection names |
| core/theme/ | Material theme, color palette, text styles |
| core/routes/ | Named routes and navigation logic |

### Models
| File | Purpose |
|------|---------|
| user_model.dart | Stores user info: uid, phone, name, role, flatNumber, fcmToken |
| visitor_model.dart | Stores visitor info: name, phone, flatNumber, status, entry/exit times |
| flat_model.dart | Stores flat info: flatNumber, block, residentIds |

### Services
| File | Purpose |
|------|---------|
| auth_service.dart | Handle OTP send/verify, sign in/out |
| user_service.dart | Create/read/update user documents in Firestore |
| visitor_service.dart | Create/read/update visitor documents, real-time streams |
| fcm_service.dart | Initialize FCM, handle notifications, manage tokens |

### Providers
| File | Purpose |
|------|---------|
| auth_provider.dart | Manage auth state, current user, login flow |
| visitor_provider.dart | Manage visitor lists, add/approve/deny/checkout actions |

### Screens
| Folder | Purpose |
|--------|---------|
| screens/auth/ | Login flow: phone input → OTP → role selection |
| screens/guard/ | Guard dashboard: add visitors, view pending, checkout |
| screens/resident/ | Resident dashboard: approve/deny visitors, view history |
| screens/admin/ | Admin dashboard: view all logs with filters |

### Widgets
| File | Purpose |
|------|---------|
| visitor_card.dart | Reusable card showing visitor info with action buttons |

