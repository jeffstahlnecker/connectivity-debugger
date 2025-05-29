# Connectivity Debugger

A Flutter app for basic device and connectivity diagnostics.

## Features

- Shows device info, connectivity status, and DNS resolution.
- On **Android**: (future) can provide detailed SIM and cellular diagnostics (with permissions).
- On **iOS**: limited to basic connectivity and device info due to Apple restrictions.

## iOS Limitations

- iOS does **not** allow third-party apps to access SIM details, signal strength, or registration state.
- Carrier name may not be available, especially on iPad or with IoT/data SIMs.
- No access to Field Test Mode or low-level radio data.
- The app will display only what is possible via public APIs.

## Android Capabilities

- (Planned) Can access SIM info, signal strength, registration state, and more (with user permission).

## Setup

1. **Clone the repo:**
   ```sh
   git clone <your-repo-url>
   cd connectivity_debugger
   ```
2. **Install dependencies:**
   ```sh
   flutter pub get
   ```
3. **iOS:**
   - Run `cd ios && pod install && cd ..`
   - Open in Xcode to set your development team for device builds.
   - Run on a real device for best results (simulator cannot access SIM/cellular info).
4. **Android:**
   - Run on a real device for full diagnostics (future feature).

## Usage

- Tap the refresh button to run diagnostics.
- Tap the info icons for explanations of each field.
- On iOS, expect limited data due to system restrictions.

## Contributing

Pull requests are welcome! Please open an issue first to discuss major changes.

## License

This project is licensed under the Business Source License 1.1 (BSL-1.1).

You may use, copy, modify, and distribute this software, but only for non-production use, research, or evaluation purposes. Production use is governed by the terms of the BSL-1.1. See the LICENSE file for details.
