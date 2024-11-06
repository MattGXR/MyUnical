# MyUnical

MyUnical is a modern and intuitive iOS application designed to help students at the University of Calabria (Unical) manage their academic information seamlessly. The app provides students with real-time access to their grades, academic progress, and allows them to simulate future grades to predict their academic standing.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Privacy and Data Security](#privacy-and-data-security)
- [License](#license)
- [Acknowledgements](#acknowledgements)
- [Contact](#contact)

## Features

- **User Authentication**
  - Secure login using Unical credentials.
  - Credentials are safely stored in the iOS Keychain.

- **Dashboard**
  - Personalized welcome message.
  - Displays current GPA (Media), a degree base calculated on the latter, and the earned and remaining credits (CFU).
  - Shows recent grades for quick overview.
  - Access to a simulation tool for predicting GPA based on potential future grades.

-  **Simulation Tool**
   - Simulate potential grades to see their impact on GPA.
   - Select grade and corresponding credits for accurate predictions.

- **Grades View (Libretto)**
  - Comprehensive list of all grades.
  - Search functionality to filter courses.
  - Detailed view of each grade, including course name, credits, exam date, and score.
  - Section through which book an exam, providing all the informations about it (date, place, hour, chairman, partecipants and notes).

- **Fees**
   - Payments Status.
   - Show invoices list with payment code, the amount, dates (due, payment and issue) and a description.
   - Payment functionality through QR code (with instructions).

- **Weekly Schedule**
   - Comprehensivelist of all lectures.
   - Search functionality to filter the lectures.
   - Access to the schedule fot each day providing possible overlaps.
   - Real time update for the schedule of the day.
   - Add new lectures putting a title, day, hours, place, notes and a color for differentiation.
   - Filtering function for ongoing lectures.

- **Settings**
  - Manage app settings and preferences.
  - Logout functionality.
  - Reload functionality.
  - Information about the user.
  - Donation section.
  - Reporting section.

- **Offline Support**
  - Data caching ensures access to grades and academic information without an internet connection.
  - Automatically loads the last fetched data when offline.
  
- **Data Synchronization**
  - Silent data fetching upon app launch to update cached data when internet connectivity is available.


## Requirements

- iOS 17.0 or later
- Xcode 15.0 or later
- Swift 5.3 or later

## Installation

1. **Clone the Repository**

   Clone the repository to your local machine using Git.

2. **Open the Project**

   Navigate to the project directory and open `MyUnical.xcodeproj` with Xcode.

3. **Install Dependencies**

   Ensure that all dependencies are installed. The project uses native SwiftUI components, so no external dependencies are required.

4. **Run the App**

   Select the desired simulator or your connected iOS device and click the **Run** button in Xcode.

## Usage

1. **Login**

   - Launch the app.
   - Enter your Unical credentials.
   - Credentials are securely stored using Keychain services.

2. **API**

   - The app shows data retrieved from Unical's Esse3 REST Api service.
   


## Privacy and Data Security

- **Credential Storage**: Your credentials are stored securely using the iOS Keychain and are never shared with third parties.
- **Data Fetching**: The app communicates directly with Unical's official APIs to fetch your academic data.
- **Personal Data**: Personal information such as your name and academic records are used solely within the app to provide you with accurate and personalized information.
- **Data Caching**: Fetched data is cached locally in JSON format, ensuring access even without an internet connection.

## License

This project is licensed under the **MyUnical Non-Commercial License**. See the [LICENSE](LICENSE.md) file for details.

## Acknowledgements

- **University of Calabria (Unical)**: For providing the APIs to access student data.

## Contact

For any questions or suggestions, please contact:

- **Name**: Mattia Meligeni
- **Email**: [myunical@mattiameligeni.it](mailto:myunical@mattiameligeni.it)
- **GitHub**: [github.com/MattGXR](https://github.com/MattGXR)
