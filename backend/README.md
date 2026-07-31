# BRL Nexus Backend

This is the Node.js, Express, and MongoDB backend for BRL Nexus, a Blockchain Research Lab Management Platform.

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```
2. Configure your `.env` file based on `.env.example`.
3. Start the application:
   ```bash
   npm run dev
   ```

## Architecture
This project follows a Clean Architecture layered approach:
- `controllers/` - Route handlers and HTTP logic
- `services/` - Core business logic
- `repositories/` - Database access layer
- `models/` - Mongoose schemas
- `routes/` - API route definitions

## Features
- Role-based Access Control (Super Admin, Admin, Coordinator, Volunteer, Viewer)
- JWT Authentication (Access & Refresh tokens)
- QR Code-based & Manual Attendance
- Analytics Dashboard Data
- Student and Member Management
- Event Management
- Request Rate Limiting
- Daily File Logging

## Available Scripts
- `npm start` - Run in production
- `npm run dev` - Run with nodemon
- `npm run lint` - Run ESLint
- `npm test` - Run tests (Jest)
