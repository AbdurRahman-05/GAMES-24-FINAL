# Games24 — Full Project Architectural & Technical Overview

Welcome to the comprehensive architecture, design, and operations guide for **Games24**, an end-to-end sports facility booking, tournament hosting, and venue management ecosystem.

---

## 1. Executive Summary

**Games24** is a multi-platform sports ecosystem designed to connect players, turf owners, and platform administrators. It eliminates manual turf booking, streamlines venue management, offers dynamic slot pricing, and automates tournament brackets.

The project is structured as a monorepo consisting of **4 primary sub-applications**:

| Component | Directory | Technology | Target Users |
| :--- | :--- | :--- | :--- |
| **Backend API** | `games24_backend` | NestJS, Prisma ORM, PostgreSQL, Multer | System Core / All Clients |
| **Super Admin Portal** | `games24_superadmin` | Next.js 16, React 19, Tailwind CSS v4 | Games24 Platform Admins |
| **Owner Mobile App** | `games24_owner_app` | Flutter (Riverpod, GoRouter) | Turf & Sports Arena Owners |
| **Player Mobile App** | `games24_player_app` | Flutter (SharedPreferences, HTTP) | Players, Athletes & Teams |

---

## 2. Monorepo Directory Structure

```text
D:\games 24\
└── games24_bundle\
    ├── games24_backend\             # NestJS + Prisma PostgreSQL API backend
    │   ├── prisma\
    │   │   └── schema.prisma        # Database models & relationships
    │   ├── src\
    │   │   ├── main.ts              # Entry point & CORS & static uploads
    │   │   ├── app.module.ts        # Root NestJS module
    │   │   ├── auth.controller.ts   # Auth, OTP, Registration & KYC endpoints
    │   │   ├── auth.service.ts      # Auth & credential validation logic
    │   │   ├── turf.controller.ts   # Public & Owner turf slots, booking & pricing
    │   │   ├── turf.service.ts      # 24-hour slot generator & pricing engine
    │   │   ├── super-admin.controller.ts # Admin approval & audit endpoints
    │   │   ├── super-admin.service.ts    # Admin verification & cancellation logic
    │   │   ├── upload.controller.ts # File & document upload engine (Multer)
    │   │   └── prisma.service.ts    # Prisma database client lifecycle
    │   ├── uploads\                 # Uploaded venue photos & KYC documents
    │   ├── package.json
    │   └── .env
    │
    ├── games24_superadmin\          # Next.js 16 Web Dashboard for Super Admins
    │   ├── src\
    │   │   ├── app\
    │   │   │   ├── page.tsx         # Registrations tab (Waiting, Verified, Cancelled)
    │   │   │   ├── admins\page.tsx  # Verified Turf Owners directory
    │   │   │   └── layout.tsx       # Root layout with navigation & theme
    │   │   ├── components\
    │   │   │   ├── Navbar.tsx       # Top bar with live stats & navigation
    │   │   │   ├── RegistrationDetailModal.tsx # Full KYC review modal
    │   │   │   └── AdminDetailModal.tsx        # Verified venue inspector modal
    │   │   └── lib\
    │   │       └── api.ts           # Type-safe API client for backend
    │   └── package.json
    │
    ├── games24_owner_app\           # Flutter Cross-Platform App for Venue Owners
    │   ├── lib\
    │   │   ├── main.dart            # ProviderScope entry point
    │   │   ├── core\                # Routing (GoRouter), Theme, Shared Widgets
    │   │   └── features\
    │   │       ├── admin\           # Turf Owner dashboard, slots & KYC screens
    │   │       ├── tournaments\     # Fixtures, brackets, live scoring
    │   │       └── shared\          # Common models & repositories
    │   └── pubspec.yaml
    │
    └── games24_player_app\          # Flutter Cross-Platform App for Players
        ├── lib\
        │   ├── main.dart            # Flutter entry point & onboarding routing
        │   ├── main_layout.dart     # 4-tab player shell (Home, Tournaments, Explore, Profile)
        │   ├── home_screen.dart     # Quick booking, featured turfs, banners
        │   ├── explore_screen.dart  # Turf directory with sport filters
        │   ├── booking_screen.dart  # Interactive slot booking & rate calculator
        │   ├── tournaments_screen.dart # Public & private tournament hub
        │   ├── booking_manager.dart # Local booking caching & state notifier
        │   └── tournament_manager.dart # Tournament state & bracket coordinator
        └── pubspec.yaml
```

---

## 3. Database Architecture & Data Models

The database is built on **PostgreSQL** using **Prisma ORM**. The schema is located at `games24_backend/prisma/schema.prisma`.

```mermaid
erDiagram
    User {
        Int id PK
        String fullName
        String mobileNumber UK
        String password
        String preferredSport
        DateTime createdAt
    }

    Otp {
        Int id PK
        String mobileNumber
        String otp
        DateTime expiresAt
    }

    AdminUser ||--o| VerifiedAdmin : "Approved by Superadmin"
    AdminUser {
        Int id PK
        String trackingCode UK
        String venueName
        String ownerName
        String ownerPhone
        String ownerEmail
        String streetAddress
        String neighborhoodArea
        Boolean isMobileVerified
        Boolean isEmailVerified
        String status "PENDING_APPROVAL | VERIFIED | CANCELLED"
        String cancelReason
        String gstin
        String panNumber
        String aadhaarNumber
        String bankAccount
        String ifscCode
        String upiId
    }

    VerifiedAdmin ||--|| AdminDashboard : "Owns"
    VerifiedAdmin ||--o{ TurfBooking : "Has Bookings"
    VerifiedAdmin ||--o{ BlockedSlot : "Manages Blocks"
    VerifiedAdmin ||--o{ SlotOffer : "Configures Offers"

    VerifiedAdmin {
        Int id PK
        Int adminUserId UK
        String venueName
        String ownerPhone
        String ownerEmail
        Float dayRate
        Float nightRate
        Float weekdayRate
        Float weekendRate
        String status
        DateTime verifiedAt
        String verifiedBy
    }

    AdminDashboard {
        Int id PK
        Int verifiedAdminId FK
        String openingTime "05:00 AM"
        String closingTime "11:00 PM"
        Int todayBookingsCount
        Int todayPaidBookings
        Float monthRevenue
        Int freeSlotsCount
        Int bookedSlotsCount
        Int blockedSlotsCount
    }

    TurfBooking {
        Int id PK
        Int verifiedAdminId FK
        String customerName
        String customerPhone
        String sport
        String courtName
        String date "YYYY-MM-DD"
        String timeSlot
        Float amount
        String paymentMethod
        String status "Confirmed | Cancelled"
    }

    BlockedSlot {
        Int id PK
        Int verifiedAdminId FK
        String date
        String timeSlot
        String reason
    }

    SlotOffer {
        Int id PK
        Int verifiedAdminId FK
        String date
        String timeSlot
        String offerType "PERCENT | PRICE"
        Float discountPercent
        Float originalPrice
        Float offerPrice
        String tagLabel "e.g. Happy Hour"
    }
```

### Key Schema Insights:
1. **Separation of Pending Application (`AdminUser`) and Active Venue (`VerifiedAdmin`):**
   - When an owner registers, their details enter `AdminUser` with status `PENDING_APPROVAL`.
   - Once verified by the Superadmin, a `VerifiedAdmin` record is generated with operational rates, and an `AdminDashboard` is initialized with real-time KPI metrics.
2. **24-Hour Slot Management:**
   - Slots are represented in human-readable hourly intervals (e.g. `"06:00 AM - 07:00 AM"`).
   - `BlockedSlot` ensures owners can lock courts for maintenance or offline bookings with a composite unique constraint `[verifiedAdminId, date, timeSlot]`.
   - `SlotOffer` permits custom discounts or "Happy Hour" pricing per slot with unique constraint `[verifiedAdminId, date, timeSlot]`.

---

## 4. Key Workflows & Business Logic

### A. Turf Owner Onboarding & Super Admin Approval Lifecycle

```mermaid
sequenceDiagram
    autonumber
    actor Owner as Turf Owner (Mobile/Web)
    participant Backend as NestJS API
    actor Admin as Super Admin (Next.js)

    Owner->>Backend: Step 1: Submit Venue & Owner Profile
    Owner->>Backend: Step 2: Request & Verify Mobile/Email OTPs
    Owner->>Backend: Step 3: Upload Venue Photos & Amenities (/upload/photo)
    Owner->>Backend: Step 4: Upload KYC Docs (Aadhaar, PAN, GST, Bank Info)
    Backend-->>Owner: Generates unique Tracking Code (e.g. TRK-XXXXXX)
    Note over Owner,Backend: Status = PENDING_APPROVAL

    Admin->>Backend: GET /super-admin/registrations (Fetch Waiting Queue)
    Admin->>Backend: POST /super-admin/registrations/:id/verify
    Backend->>Backend: 1. Update AdminUser.status = VERIFIED<br/>2. Upsert VerifiedAdmin record<br/>3. Upsert AdminDashboard (KPIs = 0)
    Backend-->>Admin: Success confirmation
    Owner->>Backend: GET /auth/admin-status/:trackingCode
    Backend-->>Owner: Returns VERIFIED status -> Owner Logs In to Dashboard
```

### B. Dynamic Slot Calculation & Player Booking

```mermaid
sequenceDiagram
    autonumber
    actor Player as Player (Player App)
    participant Backend as NestJS API
    participant DB as PostgreSQL (Prisma)
    actor Owner as Venue Owner (Owner App)

    Player->>Backend: GET /turfs/:id/slots?date=YYYY-MM-DD
    Backend->>DB: Query VerifiedAdmin, Operating Hours, Bookings, BlockedSlots & SlotOffers
    Backend->>Backend: Calculate slot status:
    Note over Backend: Check if booked -> BOOKED<br/>Check if in BlockedSlot -> BLOCKED<br/>Check Day/Night & Weekday/Weekend Rate<br/>Apply SlotOffer discount (if active)
    Backend-->>Player: Return slot list with final dynamic price & availability

    Player->>Backend: POST /turfs/:id/book (slot, customer details, payment)
    Backend->>DB: Check for race conditions (conflict check)
    Backend->>DB: Insert TurfBooking record
    Backend->>DB: Increment AdminDashboard KPIs (todayBookings, monthRevenue, GMV)
    Backend-->>Player: Booking Confirmed (Instant booking voucher)
    Owner->>Backend: GET /auth/verified-admin/:phone (Real-time dashboard refresh)
    Backend-->>Owner: Displays updated booking in live calendar
```

### C. Owner Dynamic Pricing & Slot Lockout
- **Locking Slots:** Owners can tap any slot in `AdminSlotManagerScreen` to instantly toggle a block, preventing player bookings during rain, field maintenance, or private events.
- **Promotional Pricing:** Owners can select specific off-peak slots (e.g., 11:00 AM – 03:00 PM) and attach percentage discounts (e.g., 20% off) or flat pricing (e.g., ₹800 instead of ₹1000) with custom badges like "Happy Hour".

### D. Tournament Engine
- **Public & Private Tournaments:** Both players and venue owners can organize tournaments with custom sports, formats (Knockout / League), entry fees, max teams, and prize distribution.
- **Brackets & Live Scoring:** The owner app contains a dedicated fixture generator (`advanced_fixture_engine.dart`), interactive visual bracket tree (`tournament_bracket_view.dart`), and live score updates.

---

## 5. Technology Stack Summary

| Area | Technology | Version | Purpose |
| :--- | :--- | :--- | :--- |
| **Backend Runtime** | Node.js | v20+ / ESM | Fast, non-blocking asynchronous server |
| **Framework** | NestJS | 12.0.1 | Scalable modular enterprise architecture |
| **Database ORM** | Prisma | 5.10.2 | Type-safe database client and migrations |
| **Database** | PostgreSQL | 15+ / Neon Cloud | Relational data persistence with connection pooling |
| **File Storage** | Multer / Static Serve | 2.3.0 | Secure upload of KYC files & venue images |
| **Super Admin UI** | Next.js / React | 16.4 / 19.3 | Modern Server/Client component dashboard |
| **Admin Styling** | Tailwind CSS | v4 | Modern styling with Lucide icons |
| **Owner Mobile App** | Flutter / Dart | 3.10+ | Reactive owner portal with Riverpod & GoRouter |
| **Player Mobile App** | Flutter / Dart | 3.10+ | Fluid consumer booking experience |

---

## 6. How to Run Each Application

### 1. Backend (`games24_backend`)
```powershell
cd "d:\games 24\games24_bundle\games24_backend"

# Ensure environment file is populated (.env)
# DATABASE_URL="postgresql://user:password@host/db?sslmode=require"
# PORT=3000

# Install dependencies (if not already installed)
npm install

# Generate Prisma Client & push schema
npx prisma generate
npx prisma db push

# Start NestJS development server
npm start
# Server listens at http://localhost:3000
```

### 2. Super Admin Web Portal (`games24_superadmin`)
```powershell
cd "d:\games 24\games24_bundle\games24_superadmin"

# Install dependencies
npm install

# Run development server
npm run dev
# Portal accessible at http://localhost:3001 (or default Next.js port)
```

### 3. Venue Owner App (`games24_owner_app`)
```powershell
cd "d:\games 24\games24_bundle\games24_owner_app"

# Fetch packages
flutter pub get

# Run on Chrome or connected Android/iOS device
flutter run -d chrome
# or
flutter run
```

### 4. Player Consumer App (`games24_player_app`)
```powershell
cd "d:\games 24\games24_bundle\games24_player_app"

# Fetch packages
flutter pub get

# Run on device or web
flutter run -d chrome
# or
flutter run
```

---

## 7. Recommended Next Steps & Roadmap

1. **Centralize API Base URLs in Flutter Apps:**
   - Currently, some endpoints in Flutter reference `http://localhost:3000`. Create an `EnvironmentConfig` class in both mobile apps to switch between `localhost`, local LAN IP (for physical Android/iOS testing), and production domains.
2. **JWT Authentication & RBAC Guards:**
   - Migrate simple identifier-based session checks to signed JWT tokens with NestJS `AuthGuard` on protected endpoints.
3. **Payment Gateway Integration:**
   - Replace manual payment strings with Razorpay / Cashfree / Stripe webhooks for real-time online settlement.
4. **WebSocket / Socket.io for Live Score Engine:**
   - Hook up `RealtimeScoreSyncService` directly to a NestJS WebSocket Gateway for real-time tournament spectator updates.

