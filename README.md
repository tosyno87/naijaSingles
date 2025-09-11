# NaijaSingles

NaijaSingles is a Flutter-based mobile dating application created for singles in Nigeria. The app lets users discover matches, chat, and meet new people nearby. It integrates Firebase, location services, and in-app purchases to provide a complete social experience.

## Setup

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) and set up your development environment. This project was built using **Flutter 3.32.3** with **Dart 3.5**, so ensure your SDK matches or exceeds these versions. After installation, run `flutter doctor` to confirm everything is configured correctly:

   ```bash
   flutter doctor
   ```
2. Clone this repository and navigate to the project root:

   ```bash
   git clone <repo-url>
   cd naijaSingles
   ```
3. Run the setup script to fetch dependencies and verify your environment:

   ```bash
   ./setup.sh
   ```

   The script requires an existing Flutter installation and internet access to download packages from `flutter.dev`. If these domains are blocked, setup will fail.
4. Configure Firebase by adding your `google-services.json` file to `android/app/` and `GoogleService-Info.plist` to `ios/Runner/`.
5. After setup completes, run the app on a connected device or emulator:

   ```bash
    flutter run
    ```

6. Grant location permissions when prompted. The app depends on precise
   location access to match nearby users. Android permissions are declared
   in `android/app/src/main/AndroidManifest.xml`, and iOS requires
   `NSLocationWhenInUseUsageDescription` in `ios/Runner/Info.plist`.

### Using Emulators

To run the app on an emulator:

1. **Android Emulator**:
   - Launch an Android emulator through Android Studio:
     ```bash
     # Open Android Studio and start an emulator from AVD Manager
     # Or use the command line:
     cd $ANDROID_HOME/emulator
     ./emulator -avd <emulator_name>
     ```
   - Then run the app:
     ```bash
     flutter run
     ```

2. **iOS Simulator** (macOS only):
   - Launch the iOS Simulator:
     ```bash
     open -a Simulator
     ```
   - Then run the app:
     ```bash
     flutter run
     ```

3. **List available devices**:
   ```bash
   flutter devices
   ```

4. **Run on a specific device/emulator**:
   ```bash
   flutter run -d <device_id>
   ```

### Running tests

The project includes a basic widget test. Execute all tests with:

```bash
flutter test
```

### Code analysis

To ensure the code follows lint rules, run:

```bash
flutter analyze
```

## Refactoring MVP

The repository was recently restructured into feature-focused modules using the BLoC pattern. Major additions include:

- Onboarding flow for creating and verifying user profiles.
- Home swipe cards with premium limits and location-based matching.
- Explore map and street view screens for discovering nearby users.
- Chat and call features powered by Firebase.
- Diary posts and notifications.
- In-app purchases for subscriptions.
- Multi-language support and updated themes.
- Updated to Flutter 3.32.3 and Dart 3.5 with the latest package versions.

These changes form the minimum viable product (MVP) after our refactoring effort.

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository and create a feature branch.
2. Make your changes and ensure `flutter analyze` and `flutter test` run without issues.
3. Commit your work with clear messages and open a pull request describing your changes.
4. Your code will be reviewed before merging.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for more information.
