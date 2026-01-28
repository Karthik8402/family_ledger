# Family Ledger

A shared family expense tracker built with Flutter and Firebase. This application helps families manage their finances by tracking contributions, expenses, and a shared family pool.

## Features

-   **User Authentication**: Secure sign-up and login functionality.
-   **Transaction Management**:
    -   Add **Income** or **Expense** transactions.
    -    Categorize transactions (e.g., Groceries, Rent, Salary).
    -   **Visibility Control**: Mark transactions as **Shared** (visible to the family) or **Private** (only visible to you).
-   **Family Contributions**:
    -   View total shared family pool (Income).
    -   See individual member contributions and percentage breakdown.
    -   Visual statistics with animations.
-   **Currency**: Optimized for INR (₹).

## Tech Stack

-   **Frontend**: Flutter (Dart)
-   **Backend**: Firebase (Firestore, Authentication)
-   **State Management**: Provider
-   **Utilities**: 
    -   `flutter_animate` for UI animations.
    -   `intl` for date and currency formatting.

## Getting Started

### Prerequisites
-   Flutter SDK installed (Version 3.0.0+)
-   FirebaseCLI configured

### Installation

1.  **Clone the repository**:
    ```bash
    git clone <repository-url>
    cd family_ledger
    ```

2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Firebase Setup**:
    -   Ensure `firebase_options.dart` is present in `lib/` (generated via `flutterfire configure`).
    -   This project relies on Firestore and Firebase Auth.

4.  **Run the app**:
    ```bash
    flutter run -d chrome --web-port 5000
    ```
