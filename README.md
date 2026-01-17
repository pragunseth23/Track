# Track - macOS App

Privacy-first personal finance tracker for macOS with minimal, dark-mode-first design and on-device AI.

## Features

- **Privacy-First**: All data stored locally on-device, no cloud sync required
- **Smart Categorization**: Rule-based categorization with optional AI-powered categorization using Phi-3.5-mini-instruct
- **AI-Powered Insights**: Generate detailed financial insights based on spending patterns using on-device LLM
- **Budget Tracking**: Set budgets by category with visual progress indicators
- **Transaction Management**: Add, edit, and categorize transactions with merchant name normalization
- **Month-over-Month Analysis**: Track spending trends and changes
- **Export**: Export all transaction data as JSON

## Architecture

- **Platform**: macOS 14.0+
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **Architecture**: MVVM + Domain/Repository pattern
- **Concurrency**: Async/await throughout
- **AI Model**: Phi-3.5-mini-instruct (3.8B parameters, Q4 quantization, ~2.4 GB)
- **Inference Engine**: MLX via PythonKit

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
│       ├── MLXLLMClient.swift  # MLX inference client
│       ├── OnDeviceLLMClient.swift  # LLM orchestrator
│       └── phi-3.5-mini-instruct-MLX/  # MLX model files
├── Domain/
│   ├── Repositories/           # Repository protocols and implementations
│   ├── Services/               # Business logic services
│   │   ├── CategorizationService.swift  # Transaction categorization
│   │   └── InsightsService.swift  # Financial insights generation
│   └── LLM/                    # LLM client protocol
├── Features/
│   ├── Onboarding/             # Onboarding flow
│   ├── MainTab/                # Sidebar navigation
│   ├── Home/                   # Home dashboard with insights
│   ├── Transactions/           # Transaction list and editing
│   ├── Budgets/                # Budget management
│   └── Settings/               # App settings
└── UIComponents/
    └── PieChartView.swift      # Pie chart component
```

## Setup

### Prerequisites

1. **Xcode 15.0+** with macOS 14.0+ SDK
2. **Python 3.8+** (for MLX inference)
3. **mlx-lm** Python package:
   ```bash
   pip3 install mlx-lm
   ```

### Installation

1. Open the project in Xcode
2. Ensure the MLX model is included in the app bundle:
   - The `phi-3.5-mini-instruct-MLX` directory should be in `Track/Data/LLM/`
   - Verify it's added to the app target
   - Check "Copy Bundle Resources" includes the model directory
3. Install Python dependencies:
   ```bash
   pip3 install mlx-lm
   ```
4. Build and run

## AI Model

The app uses **Phi-3.5-mini-instruct** (Microsoft) for on-device AI inference:

- **Model**: Phi-3.5-mini-instruct (3.8B parameters)
- **Format**: MLX (Apple's ML framework)
- **Quantization**: Q4 (4-bit)
- **Size**: ~2.4 GB
- **Use Cases**:
  - Transaction categorization
  - Merchant name normalization
  - Financial insights generation

### Model Status

The model is bundled with the app. Check the Settings screen to verify model availability. The app will fall back to rule-based categorization if the AI model is unavailable.

### MLX Integration

MLX inference works via PythonKit bridge to Python's mlx-lm library. Ensure Python 3.8+ and mlx-lm are installed for full AI functionality.

## Key Features

### Smart Categorization

- Automatically categorizes transactions using AI when Smart Categorization is enabled
- Handles ambiguous merchant names (e.g., "SBUX*1234-5678" → "Starbucks")
- Creates new categories dynamically based on AI suggestions
- Falls back to rule-based categorization if AI is unavailable

### AI-Powered Insights

- Generates detailed, actionable financial insights using AI
- Analyzes spending patterns and trends
- Provides month-over-month comparisons
- Offers specific recommendations based on transaction data
- Insights are generated on-demand via button press

### Mock Data

- Generate realistic test transactions for development
- Includes ambiguous merchant names to test categorization
- Useful for testing categorization and insights features

## Design System

- **Colors**: Custom dark theme optimized for readability
- **Typography**: SF Pro with monospaced fonts for numeric data
- **Spacing**: Consistent spacing scale (xs to xxxl)
- **Corner Radius**: Minimal, almost square (2-6pt)

## App Size

- **Model**: ~2.4 GB (Phi-3.5-mini-instruct, Q4)
- **App Binary**: ~5-15 MB
- **Total Download**: ~1.5-1.7 GB (compressed)
- **Installed Size**: ~2.4 GB

## Platform Requirements

### macOS
- **macOS 14.0+** (Sonoma)
- **Apple Silicon** (M1/M2/M3/M4) recommended
- **8GB+ RAM** (16GB+ for better performance)
- **Python 3.8+** with mlx-lm installed

## Future Enhancements

Potential AI-powered features to implement:
- Anomaly detection for unusual spending
- Subscription detection and management
- Budget recommendations
- Spending forecasts
- Natural language transaction search
- Financial health scoring

## License

Private project.
