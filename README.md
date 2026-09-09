# ProCut - Pro Offline-First Video Editor

ProCut is a production-grade, offline-first hybrid video editing application built with Flutter. It delivers an intuitive, high-performance multi-track timeline editing experience that functions completely offline, with cloud backup, template downloads, and royalty-free music available when online.

---

## 🎬 Core Features

- **Offline-First Timeline Editing**:
  - Multi-track timeline (Video, B-Roll, Multitrack Audio, Text Overlays, Animated Stickers).
  - High-precision playhead scrubbing and 60fps playback monitor.
  - Video clip operations: Split, Trim, Speed Ramping (0.25x - 4x), Transitions (Fade, Glitch, Wipe, Zoom).
  - Undo / Redo history stack.
- **Color Grading & Visual FX**:
  - Real-time LUT filters: *Cinematic, Vintage 90s, Cyberpunk, Noir B&W, Warm Sunset, Vibrant Pop*.
  - Color adjustment sliders for Brightness, Contrast, and Saturation.
- **Audio Studio & Voiceover Recorder**:
  - Multi-channel audio mixer with gain control.
  - Live microphone voiceover recording with real-time waveform visualization.
- **Typography & Stickers**:
  - Text overlays with typography, background highlight pills, colors, and animations (*Typewriter, Fade In, Slide Up*).
  - Sticker library with trending reactions, badges, and emojis.
- **Creative Asset Hub / Store**:
  - Browse video templates, royalty-free background beats, sound FX, and stickers.
  - Instant one-tap template import into new editing projects.
- **Cloud Backup & User Profile**:
  - Offline-first storage with automatic synchronization when connected.
  - Cloud storage quota tracker and versioned project snapshots.
- **High-Performance Export Engine**:
  - Export in multiple resolutions: 480p SD, 720p HD, 1080p FHD, 4K UHD.
  - Configurable frame rates (24, 30, 60 FPS) and bitrate quality profiles.
  - 4-pass render pipeline with progress tracking and direct share actions.

---

## 🏗️ Architecture & Technology Stack

ProCut strictly follows the **Flutter Production Architecture Standard**:
- **Architecture**: Clean Architecture (Presentation $\rightarrow$ Domain $\rightarrow$ Data) with Feature-First structure.
- **State Management & DI**: `flutter_riverpod` (StateNotifiers, Family Providers, Selectors).
- **Navigation**: `go_router` (Type-safe declarative routing).
- **Local Persistence**: `path_provider` + Atomic JSON serialization with in-memory caching fallback.
- **Design System**: Dark slate theme, electric violet & cyan accents, Google Fonts typography (`Inter`, `Space Mono`).

---

## 📂 Project Structure

```
lib/
├── main.dart                          # Application entry point
├── app/
│   ├── app.dart                       # Root ProCutApp widget
│   ├── router/                        # GoRouter configuration & route definitions
│   └── theme/                         # Colors, Typography & Dark Theme
├── core/
│   ├── constants/                     # AppConstants
│   ├── errors/                        # Exceptions & Domain Failures
│   ├── storage/                       # LocalStorageService & Providers
│   ├── utils/                         # TimecodeFormatter, IdGenerator
│   └── widgets/                       # Reusable buttons, cards, sliders, badges, waveforms
└── features/
    ├── projects/                      # Project management, CRUD & catalog
    ├── editor/                        # Multi-track timeline, playhead & canvas preview
    ├── filters_effects/               # LUT color filters & adjustment sliders
    ├── audio/                         # Voiceover recorder & audio mixer
    ├── text_stickers/                 # Typography overlays & sticker packs
    ├── asset_store/                   # Cloud templates & royalty-free music hub
    ├── cloud_sync/                    # Account profile & cloud backup manager
    └── export/                        # Multi-resolution video rendering pipeline
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.13.2 or higher)
- Dart SDK

### Installation & Run

```bash
# Clone the repository
git clone <repo-url>
cd looma

# Install dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run unit & widget tests
flutter test

# Launch the app
flutter run
```

---

## 🧪 Testing

The codebase includes automated unit and widget tests covering repositories, domain use cases, and UI smoke tests:

```bash
flutter test
```
