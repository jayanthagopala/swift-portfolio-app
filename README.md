# Swift Portfolio App

A personal asset tracking app built with SwiftUI that helps you track your investments across different countries and currencies.

## Features

- Track assets in multiple currencies (GBP, INR)
- View summaries by country/region (UK, India)
- Monitor detailed breakdown of individual assets
- Add and update asset values with specific dates
- Automatic exchange rate fetching and conversion
- Persistence across app reinstalls
- Support for both light and dark mode with vibrant UI

## Key Components

- **UK Assets**: Track ISA, Pot, and Coinbase holdings in GBP
- **India Assets**: Track Shares, Smallcase, and Mutual Funds in INR
- **Manual Data Entry**: Add or update asset values with dates
- **Currency Conversion**: Automatic conversion between GBP and INR
- **Data Persistence**: Securely save portfolio data between sessions and app reinstalls

## Screenshots

(Screenshots will be added later)

## Requirements

- iOS 16.0+
- Xcode 14.0+
- Swift 5.7+

## Installation

1. Clone the repository
2. Open `portfolio.xcodeproj` in Xcode
3. Build and run the app on your device or simulator

## Usage

- Navigate between Summary and Add tabs using the tab bar
- View your overall portfolio on the "Summary" tab
- Add or update asset values using the "Add" tab
- Use the date picker to select specific dates for entries
- View currency conversions automatically

## Technical Details

The app uses several key technologies:
- SwiftUI for the user interface
- Combine for reactive programming
- FileManager for data persistence
- URLSession for currency exchange rate fetching

## License

MIT License 