# CrisisSync

CrisisSync is a real-time crisis response and emergency coordination platform tailored for hospitality venues. Built with Flutter and Firebase, it provides dedicated interfaces for admins, staff, and guests to report, manage, and coordinate responses to emergencies and concerns efficiently.

## Key Features

### Admin Portal
- **Dashboard & Analytics**: Comprehensive overview of incidents and location statistics using responsive charts.
- **Incident Management**: Monitor active issues, triage severity, and track resolution metrics via Realtime DB & Firestore.
- **Staff Management**: Onboard and manage role-based staff members.
- **Venue Configuration**: Organize venue sections and critical locations for emergency mapping.

### Staff Interface
- **Incident Workspace**: Receive and action assigned incidents with real-time syncing.
- **Live Location Mapping**: Integrated Google Maps views to pinpoint emergencies across the venue layout.
- **Action History**: Log completed tasks and check past incident resolutions.
- **Real-Time Push Notifications**: Instant alerting regarding newly raised concerns via Firebase Cloud Messaging (FCM).

### Guest Portal
- **Rapid Concern Reporting**: Frictionless interface for guests to raise alerts directly to the staff/admin.
- **Status Tracking**: Visual indicators confirming when issues are acknowledged and tracking the resolution timeline.
- **User History View**: A simple log of previous reports and their final statuses.

### Advanced Capabilities
- **AI Integration**: Powered by Gemini (`gemini_service.dart`) for advanced incident processing, text analysis, and automated insights.
- **Automated Communications**: Integrated Email dispatching (`email_service.dart`) for external alerting and offline updates.

## Tech Stack & Dependencies

- **Frontend Framework**: Flutter (Web enabled)
- **State Management**: `provider`
- **Routing**: `go_router` for robust web URI management
- **Backend Infrastructure (Firebase)**:
  - `firebase_auth` (Role-based secure access control)
  - `firebase_database` (Realtime event synchronization)
  - `cloud_firestore` (Persistent data & configuration)
  - `firebase_messaging` (In-app and push notifications)
- **Mapping & Location**: `google_maps_flutter` & `google_maps_flutter_web`
- **UI/UX**: `flutter_animate` (motion), `fl_chart` (analytics), `google_fonts`

##  Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (`>= 3.11.4`)
- Google Maps API key & Firebase configuration (ensure `firebase.json` and `.firebaserc` are synced with your environment).

### Running Locally
To launch the web platform locally:
```bash
flutter pub get
flutter run -d chrome --web-port=8080
```
