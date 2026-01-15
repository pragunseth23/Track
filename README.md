# Track iOS App

Privacy-first personal finance tracker for iOS with minimal, dark-mode-first design.

## Features

- **Privacy-First**: All data stored locally on-device
- **Smart Categorization**: Rule-based with optional LLM-powered categorization
- **Budget Tracking**: Set budgets by category with visual progress indicators
- **Insights**: Month-over-month analysis and spending patterns
- **Export**: Export all transaction data as JSON

## Architecture

- **Platform**: iOS 17.0+
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **Architecture**: MVVM + Domain/Repository pattern
- **Concurrency**: Async/await throughout

## Project Structure

```
Track/
├── App/
│   ├── AppEntry.swift          # Main app entry point
│   └── AppState.swift          # Global app state
├── DesignSystem/
│   └── DesignSystem.swift      # Colors, typography, spacing, modifiers
├── Data/
│   ├── Models/                 # SwiftData models
│   └── LLM/                    # LLM client implementations
├── Domain/
│   ├── Repositories/           # Repository protocols and implementations
│   ├── Services/               # Business logic services
│   └── LLM/                    # LLM client protocol
├── Features/
│   ├── Onboarding/             # Onboarding flow
│   ├── MainTab/                # Main tab bar
│   ├── Home/                   # Home dashboard
│   ├── Transactions/           # Transaction list and editing
│   ├── Budgets/                # Budget management
│   └── Settings/               # App settings
└── UIComponents/
    └── PieChartView.swift      # Pie chart component
```

## Setup

1. Open the project in Xcode
2. Set deployment target to iOS 17.0+
3. Build and run

## Integration Points

### Plaid SDK
The app structure is ready for Plaid integration. See `PlaidService` placeholder in Settings.

### On-Device LLM
The app structure is ready for CoreML/MLX Swift integration. See `OnDeviceLLMClient` for implementation details.

## Design System

- **Colors**: Custom dark theme
- **Typography**: SF Pro with monospaced fonts for numeric data
- **Spacing**: Consistent spacing scale (xs to xxxl)
- **Corner Radius**: Minimal, almost square (2-6pt)

## License

Private project.
