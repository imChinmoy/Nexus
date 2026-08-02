# BRL Nexus

**BRL Nexus** is a comprehensive society management platform designed for the Blockchain Research Lab (BRL). The platform simplifies and centralizes the management of members, students, events, and attendance through an intuitive mobile application and a robust Node.js backend.

## 🌟 Detailed Features

### Authentication & Security
- **Secure Access**: Utilizes JSON Web Tokens (JWT) for secure authentication.
- **Data Protection**: Passwords are encrypted using `bcryptjs`.
- **API Security**: Implements rate-limiting (`express-rate-limit`) to prevent brute-force attacks, and `helmet` for securing HTTP headers.

### Event Management
- **Lifecycle Management**: Create, schedule, edit, and delete society events.
- **Event Details**: Keep track of venues, timings, descriptions, and assigned coordinators for every event.

### Advanced Attendance System
- **QR Code Scanning**: Uses the mobile device's camera (`mobile_scanner`) to scan attendee QR codes for lightning-fast check-ins.
- **Manual Override**: Permissions-based manual attendance marking and editing for edge cases.

### Dashboard & Analytics
- **Visual Insights**: Interactive charts and graphs (powered by `fl_chart`) displaying active members, event participation trends, and overall attendance rates.
- **Real-time Stats**: Get a bird's-eye view of society operations straight from the home screen.

### Member & Student Management
- **Centralized Database**: Maintain detailed profiles of all students and society members.
- **Participation History**: Track the events attended by each member and their engagement level.

### Reporting & Audit Logs
- **Data Export**: Generate detailed attendance and event reports and export them to CSV format for external use.
- **Audit Logging**: An immutable, transparent log tracking administrative actions (e.g., who created an event, who deleted a member) ensuring accountability.

### Notifications & Settings
- **Alerts**: System-wide notifications to keep members and volunteers informed about upcoming activities.
- **Dynamic Configuration**: Manage application settings (both user-level and system-level) dynamically without requiring deployments.

---

## 🔐 Role-Based Access Control (RBAC)

BRL Nexus implements a strict, hierarchical Role-Based Access Control system. Each role inherits the permissions of the roles below it.

### Roles & Responsibilities:
1. **SUPER_ADMIN** (Level 5)
   - Ultimate authority over the platform.
   - Can access all system settings, view audit logs, manage admins, and oversee the entire application.
2. **ADMIN** (Level 4)
   - Can manage users, create and delete events, and access advanced analytics and reports.
3. **COORDINATOR** (Level 3)
   - Responsible for specific events. Can create events, manage member lists, and oversee attendance.
4. **VOLUNTEER** (Level 2)
   - Ground-level operators. Primarily responsible for scanning QR codes to mark attendance and viewing event schedules.
5. **VIEWER** (Level 1)
   - Read-only access. Can view announcements and basic event details but cannot modify any data.

### Granular Permissions
The backend enforces specific permission checks (e.g., `attendance:mark`, `attendance:edit`, `event:add`, `member:delete`) before executing critical routes, ensuring that a Volunteer cannot accidentally delete an event.

---

## 🛠 Tech Stack

### Frontend (Mobile App)
- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **State Management**: [Riverpod](https://riverpod.dev/) (`flutter_riverpod`, `riverpod_annotation`)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Network**: [Dio](https://pub.dev/packages/dio) for optimized API requests.
- **Local Storage**: [Hive](https://pub.dev/packages/hive_flutter) (NoSQL local database) & [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage) for sensitive tokens.
- **UI & Utilities**: Google Fonts, Responsive Framework, Lottie & Animate_do (Animations), Shimmer (Loading states), FL Chart (Analytics).

### Backend (REST API)
- **Runtime**: [Node.js](https://nodejs.org/)
- **Framework**: [Express.js](https://expressjs.com/)
- **Database**: [MongoDB](https://www.mongodb.com/) via [Mongoose](https://mongoosejs.com/)
- **File Management**: `multer` & `cloudinary` (for storing profile pictures, event banners, etc.)
- **Email Services**: `nodemailer` (for sending automated emails/notifications)
- **Logging**: `winston` & `winston-daily-rotate-file` for robust application logging.

---

## 📁 Project Structure

```
Nexus/
├── backend/                # Node.js + Express backend
│   ├── src/
│   │   ├── constants/      # Roles, permissions, status codes
│   │   ├── controllers/    # Request handlers & business logic
│   │   ├── models/         # Mongoose database schemas
│   │   ├── routes/         # Express API routes
│   │   └── server.js       # Application entry point
│   ├── package.json
│   └── ...
├── frontend/               # Flutter mobile application
│   ├── lib/
│   │   ├── features/       # Feature-driven modules (auth, events, members, etc.)
│   │   └── main.dart       # App entry point
│   ├── pubspec.yaml
│   └── ...
└── bruno_api_collection.json # Bruno API collection for testing endpoints
```

## ⚙️ Getting Started

### Prerequisites
- Node.js (v18+)
- MongoDB instance (local or Atlas)
- Flutter SDK (v3.0.0+)
- Android Studio / Xcode

### Backend Setup
1. Navigate to the backend directory: `cd backend`
2. Install dependencies: `npm install`
3. Create a `.env` file in the `backend` root and configure your environment variables:
   - MongoDB URI
   - JWT Secret
   - Cloudinary Keys
   - SMTP Email credentials
4. Start the development server: `npm run dev`

### Frontend Setup
1. Navigate to the frontend directory: `cd frontend`
2. Install dependencies: `flutter pub get`
3. Run code generators (for Riverpod and Freezed):
   `flutter pub run build_runner build --delete-conflicting-outputs`
4. Configure your `.env` file in the frontend root with the Backend API Base URL.
5. Run the app: `flutter run`

## 🧪 Testing
- **Backend Tests**: Run `npm test` (uses Jest).
- **API Collection**: Import `bruno_api_collection.json` into [Bruno](https://www.usebruno.com/) to easily explore and test API endpoints.
