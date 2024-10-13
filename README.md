# MyUnical

MyUnical is a modern and intuitive iOS application designed to help students at the University of Calabria (Unical) manage their academic information seamlessly. The app provides students with real-time access to their grades, academic progress, and allows them to simulate future grades to predict their academic standing.

## Table of Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Privacy and Data Security](#privacy-and-data-security)
- [License](#license)
- [Acknowledgements](#acknowledgements)
- [Contact](#contact)

## Features

- **User Authentication**: Secure login using your Unical credentials, with credentials safely stored in the Keychain.
- **Dashboard**: A personalized dashboard displaying key academic metrics:
  - Current GPA (Media)
  - Earned Credits (CFU)
  - Recent Grades
  - Simulation tool for predicting GPA based on potential future grades.
- **Grades View (Libretto)**:
  - Comprehensive list of all grades.
  - Search functionality to filter courses.
  - Detailed view of each grade, including course name, credits, exam date, and score.
- **Simulation Tool**:
  - Simulate potential grades to see how they affect your GPA.
  - Select grade and corresponding credits.
- **Settings**:
  - Manage app settings and preferences.
  - Logout functionality.

## Screenshots

*(Include screenshots of your app here)*

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

2. **Dashboard**

   - View your personalized welcome message.
   - See your current GPA and earned credits at a glance.
   - Review your most recent grades.
   - Access the simulation tool.

3. **Grades View (Libretto)**

   - Browse all your grades.
   - Use the search bar to find specific courses.
   - Tap on a grade for more details.

4. **Simulation Tool**

   - Accessed via the Dashboard.
   - Select a potential grade and the corresponding credits.
   - Calculate to see the impact on your GPA.

5. **Settings**

   - Manage app settings.
   - Logout when needed.

## Privacy and Data Security

- **Credential Storage**: Your credentials are stored securely using the iOS Keychain and are never shared with third parties.
- **Data Fetching**: The app communicates directly with Unical's official APIs to fetch your academic data.
- **Personal Data**: Personal information such as your name and academic records are used solely within the app to provide you with accurate and personalized information.

## License

This project is licensed under the **MyUnical Non-Commercial License**. See the [LICENSE](LICENSE.md) file for details.

## Acknowledgements

- **University of Calabria (Unical)**: For providing the APIs to access student data.
- **OpenAI's ChatGPT**: For assisting in the development and refinement of the app's features and documentation.

## Contact

For any questions or suggestions, please contact:

- **Name**: Mattia Meligeni
- **Email**: [info@mattiameligeni.it](mailto:info@mattiameligeni.it)
- **GitHub**: [github.com/MattGXR](https://github.com/MattGXR)
