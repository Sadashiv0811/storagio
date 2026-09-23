# Storagio

**Storagio** is a household inventory and payment management application designed to help users organize their belongings, monitor stock levels, manage rooms and categories, track purchases and warranties, and receive timely reminders for important events such as expirations, bill payments, recharges, and renewals.

The application combines **local database storage with cloud backup and synchronization**, allowing users to maintain their inventory locally while also protecting their data against device changes or data loss.

---

## Overview

Managing household items can become difficult when information is spread across different places. Users may forget:

- Where an item is stored
- How many units are available
- When an item will expire
- Whether an item is running low
- When a warranty ends
- When a bill or recharge needs attention
- What was purchased and when
- Where important purchase information is stored
- How to recover their data after changing devices

Storagio provides a centralized solution for managing this information.

It allows users to organize items by **categories and rooms**, monitor stock conditions, maintain item history, schedule reminders, and synchronize important application data with cloud storage.

---

## Key Capabilities

### Inventory Management

Storagio provides a structured inventory system for managing household and personal items.

Users can:

- Add and edit inventory items
- Organize items by category and room
- Search for items
- Filter items by category and room
- View important item information directly from inventory cards
- Track item quantity and stock status
- Add item images using the camera or device storage
- Store purchase and warranty information
- Track item history
- Remove items with confirmation

Items can have different information depending on the selected category and room, allowing the application to provide a **dynamic item form** instead of forcing every item to use the same set of fields.

---

## Categories and Rooms

Storagio uses **categories and rooms** to organize inventory.

### Categories

Categories allow users to group similar items together.

The application supports:

- Category selection
- Category search
- Category filtering
- Category item counts
- Quick category selection through a bottom sheet
- Visual indication of the currently selected category

### Rooms

Rooms represent the physical locations where items are stored.

Users can:

- Add, Edit, Delete, Search rooms
- View all rooms in a grid
- View the number of items in each room
- View stock statistics for each room
- View all items belonging to a room

If a room is deleted, its associated items are not deleted. Instead, those items become **unorganized items** and can be assigned to another room later.

This prevents accidental loss of inventory information when a room is removed.

---

## Unorganized Items

Storagio handles items that do not currently have a valid room assignment.

The **Unorganized Items** section allows users to:

- View items with unknown or missing rooms
- Assign a room to an item
- Remove an item from the unorganized list once it receives a room
- Delete an unorganized item with confirmation
- Identify when all items have been properly organized

Items belonging to categories such as **Bills & Recharges**, which do not require a physical room, are excluded from this section.

---

## Stock Management

Storagio continuously monitors inventory stock levels.

Each item can have a stock status such as:

- **Empty**
- **Low**
- **Good**

Users can configure a **Low Stock Threshold** from Settings.

The threshold is stored locally and is automatically reflected across the application wherever stock status is calculated.

The application also provides room-level and global stock statistics, including:

- Total items
- Items with low stock
- Items with empty stock

---

## Alerts

The **Item Alerts** section provides a centralized view of inventory problems that require attention.

It includes:

### Expired Items

Items whose expiry date has passed are displayed with an option to delete them.

### Low Stock Items

Items whose quantity has reached the configured low-stock threshold are displayed with options to edit or delete them.

### Empty Stock Items

Items with no remaining stock are displayed so that users can quickly take action.

Destructive operations are protected with confirmation dialogs.

---

## Notifications and Reminders

Storagio provides a notification system for important inventory events.

There are three primary notification types:

1. **Low Stock**
2. **Expiry**
3. **Custom Reminder**

### Low Stock Notifications

Low-stock notifications inform users when an item's stock requires attention.

Tapping a low-stock notification does not require navigation to the item details screen.

### Expiry Notifications

Expiry notifications contain the required item information in their payload.

When the user taps an expiry notification, Storagio opens the corresponding **Item Details** screen.

### Custom Notifications

Custom reminder notifications can also contain the associated item information.

Tapping a custom reminder notification opens the corresponding **Item Details** screen.

The application also handles notification permission requirements for different Android versions, including Android 12 and below and Android 13 and above.

If notification permission has been permanently denied, the user can be directed to the application settings.

---

## Custom Reminders

Custom reminders are designed primarily for electronic appliances and recurring household tasks.

Users can:

- Create, Edit, Delete reminders
- Enable/Disable reminders
- Create one-time reminders
- Create repeating reminders
- View reminder title and content
- View scheduled date and time
- View whether a reminder repeats
- View whether a reminder is active

A reminder cannot be scheduled in the past.

Each electronic item can have **one custom reminder**.

After synchronization or application startup, future reminders are rescheduled according to their configuration and active state.

---

## Expiry and Warranty Tracking

Storagio stores purchase, expiry, and warranty information for items.

Expiry notifications can be automatically scheduled when appropriate dates are available.

The Item Details screen also provides a warranty overview containing:

- Remaining days
- Percentage remaining
- Visual progress bar
- Warranty status

The application validates date relationships to prevent invalid information.

For example:

- Purchase and warranty dates cannot be identical.
- Warranty date cannot be earlier than the purchase date.

---

## Item Details

The Item Details screen provides a complete view of an inventory item.

It includes:

- Item information
- Item image
- Category
- Room
- Quantity
- Stock status
- Purchase information
- Warranty information
- Item history
- Custom reminder information

Users can:

- Edit the item
- Delete the item
- Add or modify a custom reminder
- Enable or disable an existing reminder
- Delete a reminder
- View historical activity

The history section can be collapsed or expanded and is displayed from **latest to oldest**.

---

## Activity History

Storagio maintains a local activity/history system to record important changes made to inventory data.

Activities include operations such as:

- Item added, updated, deleted
- Room added, updated, deleted
- Custom reminder added, updated, deleted

Activity data is stored in the **local SQLite database** and is intentionally not stored in Firebase.

By default, the application displays available activities from:

- Today
- Yesterday

Users can further filter activities by:

- All
- Added
- Updated
- Deleted
- Today
- Yesterday
- A specific date

Activity sections can be collapsed or expanded.

Activity history is not included in backup or restore operations.

---

## Search

Storagio provides a dedicated search experience for finding inventory items quickly.

Items can be searched using:

- Item name
- Category name
- Room name

The search screen also provides random suggestions based on the user's existing:

- Items
- Categories
- Rooms

Users can select a suggestion directly instead of manually typing a search query.

Empty search input is ignored to prevent unnecessary searches.

---

## Profile Management

The profile section provides user and account information.

Users can:

- View their name, email, profile image
- Change their profile image
- Remove their profile image
- Edit their full name
- View total rooms
- View total items
- View security and privacy information

The application also handles missing or invalid image paths gracefully instead of allowing image loading errors to break the UI.

When a user logs out:

- A logout confirmation message is shown.
- Local user data is cleared.

For users who are not logged in, Storagio displays a guest profile state.

---

## Authentication

Storagio supports multiple authentication methods:

- Email and password
- Google Sign-In

Authentication is connected to the application's ViewModel layer so that authentication state can be reflected throughout the application.

---

## Cloud Backup and Synchronization

Storagio uses a combination of **local storage and Firebase cloud storage**.

Important application data can be synchronized between the device and the cloud.

The synchronization system handles:

- User data
- Rooms
- Items
- Custom reminders
- User Profile image
- Item images

The application uses a **MasterSync approach** for backup and restore operations.

Synchronization can occur automatically when appropriate or manually through the Settings screen.

For example, synchronization is offered when:

- A user logs in and cloud backup data is available.
- The user manually selects **Sync Data** from Settings.

After synchronization completes, future expiry and custom notifications are rescheduled according to the restored data.

---

## Data Management

Storagio supports two different data-clearing operations.

### Clear Device Data

This option removes application data stored on the device while retaining the user account.

### Delete Everything

This option removes both local and cloud application data.

The affected application data includes:

- Items
- Rooms
- Custom reminders
- Activity/history
- Deleted records

Expiry and custom reminder notifications are cancelled when data is cleared.

The application also checks whether local or cloud data actually exists before attempting a destructive operation and provides appropriate feedback to the user.

---

## Local and Cloud Architecture

Storagio follows a **local-first data management approach**.

Local storage is used for application operation and fast access, while Firebase provides cloud storage and synchronization capabilities.

This approach provides several benefits:

- Faster local data access
- Better offline usability
- Reduced dependency on continuous network connectivity
- Cloud backup capability
- Data recovery after device changes
- Controlled synchronization between local and cloud data

The application also checks network connectivity before performing operations that require an internet connection.

---

## UI and User Experience

Storagio includes several usability and reliability features throughout the application.

### Theme Support

Users can switch between:

- Light theme
- Dark theme

### Input Validation

Forms validate user input before saving data.

Validation is applied to areas such as:

- Authentication
- Item creation
- Room creation
- Reminder creation
- Profile information

### Password Visibility

Password fields include a visibility toggle to allow users to show or hide entered passwords.

### Image Handling

The application supports:

- Camera image capture
- Image selection from storage
- Image path persistence
- Image replacement
- Image deletion

Missing image files and invalid paths are handled gracefully.

### Text Overflow Handling

UI components are designed to handle long text without causing overflow errors.

### Reactive UI

Screens observe application state through providers and rebuild only when the relevant state changes.

This keeps UI updates focused on the data that actually changed rather than unnecessarily rebuilding entire screens.

---

## Home Dashboard

The Home screen provides a quick overview of important inventory information.

It includes:

- User profile image
- Alert count
- Stock alerts
- Expired item count
- Empty stock count
- Low stock count

The alert indicator changes according to the current inventory condition.

When expired or empty-stock items exist, their total is emphasized. Otherwise, the low-stock count is displayed.

The Home screen also manages notification initialization and rescheduling of future notifications.

---

## Settings

The Settings section provides centralized application configuration.

Users can:

- Change application theme
- Configure the low-stock threshold
- Set the default category
- Set the default room
- Enable or disable low-stock notifications
- Synchronize application data
- Clear device data
- Delete all application data
- Access login functionality

Default category and room selections are persisted using **SharedPreferences**.

---

## Default Category and Room

Storagio allows users to define their preferred default category and room.

The selection dialog supports:

- Category search
- Room search
- Clearing the search field
- Immediate list restoration after clearing the search
- Ignoring empty search input
- Persisting the selected category
- Persisting the selected room

The selected category and room are displayed first when appropriate, making frequent inventory operations faster.

---

## Room-Based Inventory

A dedicated room view allows users to inspect everything stored in a particular room.

It provides:

- All items belonging to the room
- Item count
- Stock status
- Empty stock indication
- Low stock indication
- Good stock indication
- Add item functionality
- Item details navigation

This provides a physical-location-oriented view of the inventory in addition to the category-oriented view.

---

## Help and Support

The Profile section includes a Help & Support area containing:

### FAQs

Common questions and answers to help users understand the application.

### Contact

Provides the application's support contact information.

### Report

Allows users to submit an issue or message using a form containing information such as:

- User name
- User email
- User message

Submitted reports are stored in Firebase.

### Guide

Provides basic instructions explaining how to use the application's primary functionality.

---

## Firebase App Check

Storagio uses **Firebase App Check** to help verify that requests sent to Firebase originate from the legitimate application environment.

This provides an additional layer of protection for Firebase-backed operations.

---

## Reliability and Edge-Case Handling

Storagio includes defensive handling for common application edge cases.

Examples include:

- Missing image files
- Invalid image paths
- Empty search fields
- Duplicate item names
- Duplicate room names
- Invalid reminder dates
- Invalid purchase/warranty date combinations
- Deleted rooms containing items
- Missing room assignments
- Missing local data
- Missing cloud data
- Permanently denied notification permissions
- Different Android notification permission behavior
- Text overflow
- Changes to shared application settings

These checks are intended to keep the application stable and provide predictable behavior during normal and exceptional usage.

---

## Target Users

Storagio is designed for a wide range of users.

### Families and Homeowners

For organizing household items, groceries, appliances, important documents, warranties, and purchase records.

### Working Professionals

For managing household inventory while keeping track of bills, recharges, warranties, renewals, and other time-sensitive tasks.

### Students and Renters

For managing belongings and shared living spaces.

### Senior Citizens

For maintaining a simple record of where important items are stored and remembering essential purchases or renewals.

### Small Home-Based Businesses

For lightweight inventory management without the complexity of a full enterprise inventory system.

### Frequent Online Shoppers

For maintaining purchase information, product details, warranties, and related records.

---

## Problems Solved

Storagio focuses on solving several common household management problems:

| Problem | Storagio Solution |
|---|---|
| Forgetting where items are stored | Organize items by rooms |
| Difficulty finding items | Search and filter inventory |
| Running out of important products | Low-stock and empty-stock tracking |
| Overstocking products | Quantity and stock monitoring |
| Forgetting expiry dates | Expiry tracking and notifications |
| Forgetting warranties | Warranty information and progress tracking |
| Forgetting bills and recharges | Custom reminders |
| Losing records after changing devices | Cloud backup and synchronization |
| Disorganized inventory after deleting rooms | Unorganized Items management |
| No history of changes | Local activity/history tracking |
| Difficult household inventory management | Centralized inventory dashboard |

---

## Data Storage

Storagio uses different storage mechanisms based on the nature of the data.

| Storage | Purpose |
|---|---|
| SQLite | Local application data and activity/history |
| Firebase | Cloud backup, synchronization, and submitted support reports |
| SharedPreferences | Default category, default room, and lightweight application preferences |
| Local file system | User and item image files |

The separation of local, cloud, preference, and file-based storage allows each type of information to be handled according to its requirements.

---

## Technology

Storagio is built using modern Flutter development practices.

### Application

- **Flutter**
- **Dart**

### Architecture

- MVVM
- Riverpod
- ViewModel-based application logic
- Reactive state management
- Provider-based UI updates

### Local Storage

- SQLite
- SharedPreferences
- Local file storage

### Cloud Services

- Firebase
- Firebase Authentication
- Firebase cloud storage/database services
- Firebase App Check

### Device Features

- Camera
- Image picker
- Local notifications
- Android notification permissions
- Application settings
- Network connectivity detection

---

## Application Design Philosophy

Storagio follows a practical **local-first and reactive architecture**.

The application aims to keep frequently accessed information available locally while using cloud services for synchronization and backup.

UI screens observe application state rather than manually managing unrelated data changes. When the relevant provider state changes, only the required parts of the UI are rebuilt.

This approach improves:

- Responsiveness
- Maintainability
- Data consistency
- Separation of concerns
- Reusability
- User experience

---

## Summary

Storagio is more than a simple inventory application. It combines **household inventory management, stock monitoring, room organization, warranty tracking, expiry notifications, custom reminders, activity history, local storage, cloud backup, and synchronization** into a single application.

Its goal is to make household information easier to organize, easier to find, and harder to forget.

By combining local-first data access with cloud synchronization and automated notifications, Storagio provides users with a practical way to manage everyday belongings, purchases, warranties, bills, recharges, and recurring household responsibilities in one place.

---