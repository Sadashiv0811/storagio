# Storagio

**Storagio** is a Flutter-based household inventory and payment management application that helps users organize belongings, track stock, manage rooms and categories, monitor purchases and warranties and receive reminders for expirations, bills, recharges and renewals.

It follows a **local-first architecture** with SQLite for local data and Firebase for cloud backup and synchronization.

## ✨ Features

- 📦 **Inventory Management**
  - Add, edit, search and organize household items
  - Manage categories and rooms
  - Track quantities and stock status
  - Add item images using camera or device storage
  - Store purchase and warranty information
  - Maintain item history

- 🏠 **Room & Category Management**
  - Create, edit, delete and search rooms
  - Organize items by room and category
  - View room-level inventory and stock statistics
  - Automatically move items to **Unorganized Items** when their room is deleted

- 📊 **Stock Monitoring**
  - Empty, Low and Good stock statuses
  - Configurable low-stock threshold
  - Global and room-level stock statistics

- 🔔 **Alerts & Notifications**
  - Low-stock notifications
  - Expiry notifications
  - Custom reminders
  - Automatic reminder rescheduling

- 🛡️ **Warranty & Purchase Tracking**
  - Track purchase and warranty dates
  - View warranty progress and status
  - Validate purchase and warranty dates

- ⏰ **Custom Reminders**
  - One-time and repeating reminders
  - Enable or disable reminders
  - Create, edit and delete reminders

- 🔐 **Authentication**
  - Email/password authentication
  - Google Sign-In
  - Firebase App Check

- ☁️ **Cloud Backup & Sync**
  - Local-first data management
  - Firebase cloud backup and synchronization
  - MasterSync-based backup and restore
  - Supports user data, rooms, items, reminders and images

- 📝 **Activity History**
  - Tracks item, room and reminder changes
  - Stored locally in SQLite
  - Supports filtering by action and date

- 🔎 **Search**
  - Search by item, category or room
  - Search suggestions from existing data

- ⚙️ **Settings**
  - Light/Dark theme
  - Low-stock threshold
  - Default category and room
  - Notification settings
  - Data synchronization and clearing

## 🏗️ Architecture

Storagio follows a **local-first and reactive architecture**.

- **MVVM**
- **Riverpod**
- ViewModel-based business logic
- Reactive provider-based UI updates
- SQLite local database
- Firebase cloud synchronization

This architecture improves responsiveness, maintainability and separation of concerns.

## 💾 Data Storage

| Storage | Purpose |
|---|---|
| SQLite | Local application data and activity history |
| Firebase | Cloud backup, synchronization and support reports |
| SharedPreferences | Application preferences |
| Local File System | User and item images |

## 🛠️ Technology Stack

**Application**
- Flutter
- Dart

**Architecture & State Management**
- MVVM
- Riverpod

**Storage**
- SQLite
- SharedPreferences
- Local file storage

**Firebase**
- Firebase Authentication
- Firebase cloud services
- Firebase App Check

**Device Features**
- Camera
- Image Picker
- Local Notifications
- Android Notification Permissions
- Network Connectivity Detection

## 🎯 Problems Solved

Storagio helps users:

- Find where household items are stored
- Monitor stock and avoid running out of important products
- Track expiry dates and warranties
- Remember bills, recharges and renewals
- Keep purchase records organized
- Recover data through cloud backup
- Maintain a history of important changes

## 📱 Target Users

- Families and homeowners
- Working professionals
- Students and renters
- Senior citizens
- Small home-based businesses
- Frequent online shoppers

## 🚀 Design Philosophy

Storagio combines **local-first data access, reactive UI, cloud synchronization and automated notifications** to provide a centralized solution for managing household belongings, purchases, warranties, bills and recurring responsibilities.