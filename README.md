# Track - macOS Finance Tracker

Privacy-first personal finance tracker for macOS with on-device AI insights.

## Features

- **On-Device AI Insights**: Generate financial insights using Phi-3.5-mini-instruct (MLX)
- **Transaction Tracking**: View and manage transactions with rule-based categorization
- **Spending Analysis**: Month-to-date totals, category breakdowns, and month-over-month trends
- **Privacy-First**: All data stored locally, no cloud sync
- **Export**: Export transaction data as JSON

## Requirements

- **macOS 14.0+** (Sonoma)
- **Apple Silicon** (M1/M2/M3/M4) - GPU required for MLX inference
- **Xcode 15.0+**
- **Python 3.13+** with `mlx-lm` installed:
  ```bash
  /opt/homebrew/opt/python@3.13/Frameworks/Python.framework/Versions/3.13/bin/python3.13 -m pip install mlx-lm --break-system-packages
  ```

## Setup

1. Clone the repository
2. Open `Track.xcodeproj` in Xcode
3. Ensure `phi-3.5-mini-instruct-MLX` is in `Track/Data/LLM/` and added to "Copy Bundle Resources"
4. Install Python dependencies (see Requirements)
5. Build and run

## AI Model

- **Model**: Phi-3.5-mini-instruct (3.8B parameters, Q4 quantization)
- **Size**: ~2.4 GB
- **Format**: MLX (Apple's ML framework)
- **Use Case**: Financial insights generation only
- **Inference**: GPU (Metal) via PythonKit bridge to `mlx-lm`

Model status is shown in Settings. The app falls back to deterministic insights if the model is unavailable.

## Architecture

- **Platform**: macOS 14.0+
- **Language**: Swift 5.9+
- **UI**: SwiftUI with custom design system
- **Data**: SwiftData
- **Pattern**: MVVM + Domain/Repository
- **Concurrency**: Async/await

## Project Structure

```
Track/
├── App/                    # App entry and state
├── Data/
│   ├── Models/            # SwiftData models (Transaction, Category, Insight)
│   └── LLM/               # MLX client and model files
├── Domain/
│   ├── Repositories/      # Data access layer
│   ├── Services/          # Business logic (Categorization, Insights)
│   └── LLM/              # LLM client protocol
├── Features/
│   ├── Home/             # Dashboard with insights
│   ├── Transactions/     # Transaction list (read-only)
│   ├── Settings/         # App configuration
│   └── Onboarding/       # First-run flow
├── DesignSystem/         # Colors, typography, spacing
└── UIComponents/        # Reusable components
```

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Notes

- Transactions are read-only (no editing)
- Categorization is rule-based only
- AI is used exclusively for insights generation
- Model uses GPU (Metal) for inference on Apple Silicon
