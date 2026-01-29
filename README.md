# Family Ledger

A shared family expense tracker built with Flutter and Firebase. This application helps families manage their finances by tracking contributions, expenses, and a shared family pool.

## Features

-   **User Authentication**: Secure sign-in using Google.
-   **Transaction Management**:
    -   Add **Income** or **Expense** transactions.
    -   Categorize transactions (e.g., Groceries, Rent, Salary).
    -   **Visibility Control**: Mark transactions as **Shared** (visible to the family) or **Private** (only visible to you).
-   **Family Contributions**:
    -   View total shared family pool (Income).
    -   See individual member contributions and percentage breakdown.
    -   Visual statistics with animations.
-   **Currency**: Optimized for INR (₹).

## Tech Stack

-   **Frontend**: Flutter (Dart)
-   **Backend**: 
    -   **Database**: Firebase Cloud Firestore
    -   **Authentication**: Google Sign-In (managed via Firestore profiles)
-   **State Management**: Provider
-   **Utilities**: 
    -   `flutter_animate` for UI animations.
    -   `intl` for date and currency formatting.
    -   `fl_chart` for statistical graphs.

## Getting Started

### Prerequisites
-   Flutter SDK installed (Version 3.0.0+)
-   Firebase CLI configured
-   Google Cloud Project with simple OAuth setup

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

3.  **Configuration**:
    -   **Firebase**: Ensure `firebase_options.dart` is present in `lib/` (generated via `flutterfire configure`).
    -   **Environment**: Create a `.env` file in the root if required (consult project maintainer for keys).
    -   **Google Sign-In**: 
        -   Authorise your local development port (e.g., `http://localhost:5000`) in the Google Cloud Console.
        -   See `google_cloud_guide.md` for troubleshooting "App Verification" or "Loopback IP" warnings.

4.  **Run the app**:
    ```bash
    # Run on Chrome with a fixed port (required for Google Sign-In)
    flutter run -d chrome --web-port 5000

    # Build for Production (if needed locally)
    flutter build web --release --no-tree-shake-icons
    ```

## Project Structure

-   `lib/screens`: UI screens (Login, Home, Add Transaction).
-   `lib/services`: Service layer for Firestore and Auth.
-   `lib/widgets`: Reusable UI components.
-   `lib/models`: Data models.
-   `assets/images`: Project images and logos.
