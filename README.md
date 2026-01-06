# Contribution Reminder & Tracking App

A Flutter application designed to help organizations, student councils, and groups efficiently manage and monitor contributions. The app automates reminders, tracks payments, and provides real-time updates and reports to ensure transparency and convenience in managing financial records.

## Features

### Member Features
- **Home Dashboard**: View current balance, next due date, and contribution summary
- **Contributions**: View personal contribution history with filtering options
- **Reminders**: Track upcoming and overdue contribution reminders
- **Profile**: Manage account information and settings

### Admin Features
- **Dashboard**: Overview of total collections, member statistics, and quick actions
- **Members Management**: Add, edit, deactivate, and manage members
- **Contributions Management**: Record payments, update status, and manage contribution records
- **Reminders**: Configure and send automated reminders to members
- **Reports**: Generate contribution summaries and analytics
- **Settings**: Configure organization details and system preferences

## Technology Stack

- **Framework**: Flutter (Dart SDK ^3.9.0)
- **State Management**: Provider
- **Database**: SQLite (sqflite) for local storage
- **Notifications**: flutter_local_notifications for push reminders
- **UI**: Material Design 3 with custom theming
- **Platforms**: Android, iOS

## Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── models/              # Data models (Member, Contribution, Reminder, Organization)
├── providers/          # State management providers
├── screens/            # UI screens
│   ├── admin/         # Admin screens
│   └── member/        # Member screens
├── services/          # Database and business logic services
└── utils/             # Utility functions and helpers
```

## Database Schema

The app uses SQLite with the following tables:
- `members`: Member information
- `contributions`: Contribution records
- `reminders`: Reminder history
- `organizations`: Organization details
- `users`: User authentication

## Usage

### First Time Setup

1. Register a new account (or login if you have one)
2. If registering, provide:
   - Full Name
   - Member ID
   - Email
   - Password
   - Organization ID

### For Members

1. Login to view your contribution dashboard
2. Check the Home tab for your current balance and next due date
3. View Contributions tab for detailed history
4. Check Reminders tab for notifications about upcoming or overdue payments
5. Update your profile in the Profile tab

### For Admins

1. Login with admin credentials
2. Use Dashboard to get an overview of collections and statistics
3. Add members in the Members tab
4. Record contributions in the Contributions tab
5. Send reminders manually or configure automated reminders
6. Generate reports in the Reports tab
7. Configure organization settings in Settings tab

## Key Features

- **Automated Reminders**: System automatically sends reminders for due and overdue contributions
- **Real-time Updates**: Contribution status updates in real-time
- **Search & Filter**: Search members and filter contributions by various criteria
- **Reports**: Generate detailed reports by member, date range, or status
- **Secure Authentication**: Password hashing and secure storage

## Future Enhancements

- Cloud sync (Firebase/Backend API)
- Multi-organization support
- Payment gateway integration
- Email/SMS notifications
- PDF/Excel report export
- Dark mode support
- Multi-language support

## Developed By

MARY JOY S. CARBALLO & CHRISTINE MAGTUBA

## License

This project is for educational purposes.
