# Smart Library Management System (iOS Client)

A modern, production-grade native iOS application built with SwiftUI for intelligent university/public library seat reservation, check-in, and occupancy management.

Built for iOS 17.0+ using native Swift concurrency (`async`/`await`), Supabase Swift SDK, and AVFoundation.

---

## Table of Contents
1. [Key Features](#key-features)
2. [Architecture & Project Structure](#architecture--project-structure)
3. [Technology Stack](#technology-stack)
4. [Prerequisites](#prerequisites)
5. [Setup & Configuration](#setup--configuration)
6. [Permissions](#permissions)
7. [Running the Application](#running-the-application)
8. [Mock Mode vs Production Mode](#mock-mode-vs-production-mode)
9. [QR Code Specifications & Demo Payloads](#qr-code-specifications--demo-payloads)
10. [Supabase RPC Contract](#supabase-rpc-contract)
11. [Realtime Synchronization & Fallbacks](#realtime-synchronization--fallbacks)
12. [Testing Status](#testing-status)

---

## Key Features

- **Supabase Authentication**: Email/password sign-up, sign-in, session persistence across app launches, and sign-out.
- **Entry QR Gatekeeper**: Physical verification requirement before seat reservation. Prevents remote seat hoarding.
- **Dynamic Interactive Seat Map**: Real-time floor plan visualization with color-coded seat statuses:
  - 🟢 **Available** (Emerald)
  - 🔴 **Occupied** (Crimson)
  - 🟡 **Temporarily Away / Grace Period** (Amber)
  - 🔵 **My Assigned Seat** (Electric Indigo)
- **Rule-Based Recommendation Engine**: Client-side heuristic ranking based on Quiet Zone, Power Outlet, and Desk Lamp preferences.
- **Atomic Seat Booking**: Synchronous backend validation preventing race conditions and double bookings.
- **Grace Period (Stepping Out)**: 20-minute temporary leave mechanism with authoritative server-provided countdown timer (`grace_deadline`).
- **Exit QR Checkout**: Clear options to step out temporarily or vacate and release seat permanently.
- **Dual Realtime Sync**: Subscribes to Supabase Realtime Broadcast (`library:<uuid>`) for `seat-map-changed` events, with an automatic 7-second polling fallback while the map is on-screen.

---

## Architecture & Project Structure

The project follows a clean MVVM (Model-View-ViewModel) architecture with dependency injection and reactive state bindings:

```
ios/
├── SmartLibrary.xcodeproj/            # Generated Xcode project
├── README.md                          # This documentation file
├── SmartLibrary/
│   ├── App/
│   │   ├── SmartLibraryApp.swift      # App lifecycle entry point
│   │   └── AppState.swift             # Central app state machine & session manager
│   ├── Models/
│   │   ├── QRPayload.swift            # QR parser model & validation
│   │   ├── Seat.swift                 # Seat map model & availability enums
│   │   ├── RPCModels.swift            # Decodable backend RPC response contracts
│   │   └── Recommendation.swift       # Heuristic recommendation models
│   ├── Services/
│   │   ├── LibraryServiceProtocol.swift # Contract for backend operations
│   │   ├── SupabaseService.swift      # Real Supabase Auth & RPC client
│   │   ├── MockLibraryService.swift   # Offline mock data provider for demo/testing
│   │   ├── RealtimeService.swift      # Supabase Realtime Broadcast & polling manager
│   │   └── QRCodeScannerService.swift # AVFoundation camera capture engine
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift        # Authentication logic & validation
│   │   ├── EntryScannerViewModel.swift# Entry QR processing & validation
│   │   ├── SeatMapViewModel.swift     # Map rendering, filtering, & booking
│   │   ├── MySeatViewModel.swift      # Active reservation & grace countdown
│   │   └── ExitScannerViewModel.swift # Exit QR validation & checkout flows
│   ├── Views/
│   │   ├── Auth/AuthView.swift
│   │   ├── Entry/
│   │   │   ├── EntryScannerView.swift
│   │   │   └── QRScannerCameraView.swift
│   │   ├── SeatMap/
│   │   │   ├── SeatMapView.swift
│   │   │   ├── SeatGridView.swift
│   │   │   ├── SeatNodeView.swift
│   │   │   ├── FilterBarView.swift
│   │   │   ├── RecommendationCardView.swift
│   │   │   └── SeatDetailSheet.swift
│   │   ├── Session/
│   │   │   ├── MySeatView.swift
│   │   │   └── GracePeriodCountdownView.swift
│   │   ├── Exit/
│   │   │   ├── ExitScannerView.swift
│   │   │   └── ExitChoiceSheet.swift
│   │   └── Common/ToastView.swift
│   ├── Components/
│   │   ├── PrimaryButton.swift
│   │   ├── StatCard.swift
│   │   ├── StatusBadge.swift
│   │   └── FacilityPill.swift
│   ├── Utilities/
│   │   ├── AppConfig.swift            # Configuration loader (plist + env)
│   │   ├── Theme.swift                # Dark-mode first design tokens & typography
│   │   ├── HapticFeedback.swift       # Tactile iOS feedback utility
│   │   └── DateFormatterHelper.swift  # ISO-8601 parser & timer calculations
│   └── Resources/
│       ├── Info.plist                 # Bundle settings & Camera usage permission
│       ├── AppConfig.plist            # Active configuration
│       ├── AppConfig.example.plist    # Sanitized template
│       └── Assets.xcassets/           # Icons and accent colors
└── Tests/
    ├── ModelDecodingTests.swift       # Backend RPC decoding & error parsing tests
    ├── QRCodeParserTests.swift        # QR validation, trimming, & error handling tests
    └── RecommendationEngineTests.swift# Preference ranking & occupancy exclusion tests
```

---

## Technology Stack

- **Platform**: iOS 17.0+
- **Language**: Swift 5.10 / Swift 6 compatible
- **UI Framework**: SwiftUI
- **SDK**: `supabase-swift` (v2.55.4+) via Swift Package Manager
- **Camera Scanning**: `AVFoundation` (`AVCaptureSession`, `AVCaptureMetadataOutput`)
- **Concurrency**: Native Swift Concurrency (`async`/`await`, `MainActor`, `Sendable`)

---

## Prerequisites

1. **macOS Sonoma / Sequoia** (macOS 14.0+)
2. **Xcode 15.0+** (tested and verified with Xcode 16 / 27)
3. Command Line Tools installed (`xcode-select --install`)
4. An active Supabase project with database migrations applied (or use Mock Mode for offline demo)

---

## Setup & Configuration

### 1. Configure Supabase Credentials

Copy the template configuration file:
```bash
cp ios/SmartLibrary/Resources/AppConfig.example.plist ios/SmartLibrary/Resources/AppConfig.plist
```

Open `ios/SmartLibrary/Resources/AppConfig.plist` in Xcode or a text editor and fill in your Supabase project parameters:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>SUPABASE_URL</key>
    <string>https://xyzcompany.supabase.co</string>
    <key>SUPABASE_ANON_KEY</key>
    <string>eyJhbGciOi...[YOUR_ANON_KEY]</string>
    <key>DEFAULT_LIBRARY_ID</key>
    <string>11111111-1111-4111-8111-111111111111</string>
    <key>ENABLE_MOCK_MODE</key>
    <false/>
</dict>
</plist>
```

> **SAFETY NOTICE**:
> - Only use the `anon` (public publishable) key in the iOS client.
> - **NEVER** commit or embed the Supabase `service_role` secret key into this application.
> - `AppConfig.plist` can also be overridden at runtime via process environment variables: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `ENABLE_MOCK_MODE=1`.

---

## Permissions

The app requires camera access to scan physical QR codes at entry and exit terminals:

- **Key**: `NSCameraUsageDescription`
- **Value**: `"SmartLibrary requires camera access to scan entry and exit QR codes at the library gates."`
- Configured in [Info.plist](file:///Users/kiet21/Documents/Desk_guard/ios/SmartLibrary/Resources/Info.plist).

*Note for Simulator / Demo*: When running in the iOS Simulator where a physical camera is unavailable, the scanner interface gracefully displays a fallback UI with:
1. One-tap "Simulate Valid QR Scan" button.
2. Manual payload entry text field for debugging edge cases.

---

## Running the Application

### Option A: From Xcode GUI
1. Open `ios/SmartLibrary.xcodeproj` in Xcode:
   ```bash
   open ios/SmartLibrary.xcodeproj
   ```
2. Select an iOS Simulator destination (e.g., **iPhone 16** or **iPhone 17**).
3. Press `Cmd + R` to build and run.
4. Press `Cmd + U` to execute unit tests.

### Option B: From Terminal (`xcodebuild`)
To build the debug application:
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project ios/SmartLibrary.xcodeproj \
  -scheme SmartLibrary \
  -destination 'generic/platform=iOS Simulator' \
  build CODE_SIGNING_ALLOWED=NO
```

To run the full unit test suite:
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test \
  -project ios/SmartLibrary.xcodeproj \
  -scheme SmartLibrary \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO
```

---

## Mock Mode vs Production Mode

To facilitate rapid UI demonstration, offline pitching, or testing without an active network connection, a dedicated **Mock Mode** toggle is provided:

- Located directly on the **Sign In** screen footer (*"Testing without Supabase? Tap for Mock Demo"*).
- Or permanently enabled by setting `ENABLE_MOCK_MODE = true` in `AppConfig.plist`.

**Production Mode Safeguards**:
- In production mode, the app connects directly to the Supabase client.
- Failures (network timeouts, unavailable seats, expired sessions) are surfaced transparently to the user; the app **never silently falls back to fake bookings in production**.

---

## QR Code Specifications & Demo Payloads

QR codes are structured with strict pipe-delimited syntax:
`SLMS|<ACTION>|<LIBRARY_UUID>`

### Demo Payloads:
- **ENTRY QR**:
  ```
  SLMS|ENTRY|11111111-1111-4111-8111-111111111111
  ```
- **EXIT QR**:
  ```
  SLMS|EXIT|11111111-1111-4111-8111-111111111111
  ```

*Security Disclosure*: As specified for this hackathon version, static QR codes serve as demo identifiers and state-gate tokens, not cryptographically verifiable proof of physical presence.

---

## Supabase RPC Contract

All backend state mutations are executed via authoritative PostgreSQL RPC functions:

| RPC Function | Signature | Return Structure | Error Codes Handled |
|---|---|---|---|
| `get_seat_map` | `p_library_id: UUID` | `[SeatMapItem]` | Empty list on invalid library |
| `get_my_state` | `p_library_id: UUID` | `MyStateResponse` | Tolerates `null` visit & booking |
| `scan_entry` | `p_library_id: UUID` | `ScanEntryResponse` | `ALREADY_INSIDE`, `LIBRARY_NOT_FOUND` |
| `book_seat` | `p_seat_id: UUID` | `BookSeatResponse` | `SEAT_UNAVAILABLE`, `ALREADY_HAS_SEAT`, `NOT_INSIDE_LIBRARY`, `NO_ACTIVE_VISIT`, `UNAUTHORIZED` |
| `start_grace_period` | `p_library_id: UUID` | `GracePeriodResponse` | `NO_ACTIVE_BOOKING`, `ALREADY_ON_GRACE` |
| `leave_library` | `p_library_id: UUID` | `LeaveLibraryResponse` | `NO_ACTIVE_VISIT` |

---

## Realtime Synchronization & Fallbacks

- **Broadcast Channel**: `library:11111111-1111-4111-8111-111111111111`
- **Broadcast Event**: `seat-map-changed`
- **Fallback Polling**: When `Realtime` is connecting or unavailable, the `RealtimeService` automatically triggers a poll every 7 seconds while the seat map is actively mounted on screen.
- **App Lifecycle**: Full state synchronization is automatically triggered upon returning from background (`scenePhase == .active`).

---

## Testing Status

| Area | Tested / Verified | Details |
|---|---|---|
| **Compilation & Project Build** | ✅ **Passed** | Built cleanly via `xcodebuild` with Xcode 16/27 toolchain. |
| **Model Decoding & Null Tolerances** | ✅ **Passed (5/5)** | Verified JSON decoding with null visits, active visits, date formatting, and RPC error mapping. |
| **QR Code Parser** | ✅ **Passed (8/8)** | Validated prefix matching, UUID syntax, unknown action rejection, and whitespace tolerance. |
| **Recommendation Engine** | ✅ **Passed (4/4)** | Verified that occupied seats are strictly excluded and preference weights sort matches first. |
| **Total Test Suite** | ✅ **17/17 Passed** | Executed in iPhone 17 Simulator environment with zero failures. |
| **Physical Camera Hardware** | ⚠️ Simulator Simulated | Tested using simulator fallback buttons & mocks; physical device test pending deployment. |
| **Live Remote Supabase DB** | ⚠️ Config Ready | Configured for real endpoints; requires live Supabase migration deployment to connect. |
