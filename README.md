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

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository and create a feature branch.
2. Make your changes and ensure `flutter analyze` and `flutter test` run without issues.
3. Commit your work with clear messages and open a pull request describing your changes.
4. Your code will be reviewed before merging.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for more information.
