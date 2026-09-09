# ProCut Architecture Documentation

## Overview
**ProCut** is built strictly following the **Flutter Production Architecture Standard**:
- **Clean Architecture** (Separation of Presentation, Domain, and Data layers)
- **Feature-First Organization**
- **Repository Pattern** with Dependency Inversion
- **Riverpod (2.x)** for State Management & Dependency Injection
- **GoRouter** for Declarative Navigation
- **Offline-First Persistence** with JSON Atomic Storage & In-Memory Fallbacks

---

## 1. Architectural Layers & Dependency Rule

```
Presentation Layer (UI Screens, Widgets, Riverpod Controllers)
       ↓
Domain Layer (Entities, Use Cases, Repository Contracts)
       ↓
Data Layer (Models, Repositories Impl, Local/Remote Data Sources)
```

**Mandatory Rule**: The UI **never** accesses Data Sources or Infrastructure directly. All interactions flow through Use Cases and Riverpod Notifiers.

---

## 2. Feature Structure

Each feature inside `lib/features/` adheres to the tripartite structure:

```
lib/features/<feature_name>/
├── domain/
│   ├── entities/      # Pure business entities & enums
│   ├── repositories/  # Abstract repository interfaces
│   └── usecases/      # Single-responsibility business logic
├── data/
│   ├── models/        # JSON & DB serializable models
│   ├── datasources/   # Local/Remote storage & platform bridges
│   └── repositories/  # Repository implementations
└── presentation/
    ├── providers/     # StateNotifiers, Providers & Filter Selectors
    ├── screens/       # Full route screen pages
    └── widgets/       # Modular UI components & bottom sheets
```

---

## 3. Features Implemented

1. **`projects`**:
   - Local JSON-persisted project catalog.
   - Project CRUD, duplication, aspect ratio selection, metadata updates.
   - Seed data generator with pre-configured cinematic & vlog projects.

2. **`editor` (Core Multi-Track Timeline Engine)**:
   - High-performance 60fps playhead ticker and scrubbing.
   - Non-linear multi-track editing: Video, Multitrack Audio, Text overlays, Animated Stickers.
   - Clip operations: Split at playhead, Trim in/out handles, Speed ramping (0.25x - 4.0x), Transitions (Fade, Glitch, Wipe, Zoom).
   - Undo/Redo stack with snapshot recovery.

3. **`filters_effects`**:
   - Hardware-accelerated Color Filter matrices (Cinematic, Noir Monochrome, Cyberpunk, 90s Vintage, Warm Sunset, Vibrant Pop).
   - Parameter adjustments: Brightness, Contrast, and Saturation sliders with real-time viewport feedback.

4. **`audio`**:
   - Multitrack audio mixer with channel gain controls.
   - Live Voiceover studio with real-time waveform visualization, sample buffer, and timeline insertion.

5. **`text_stickers`**:
   - Text overlay engine with custom typography (Google Fonts), sizing, colors, background pills, and animations (Typewriter, Fade, Slide Up).
   - Sticker library with categorized animated emojis and badges.

6. **`asset_store`**:
   - Online Creative Asset Hub for video templates, royalty-free background music, sound FX, and LUTs.
   - Instant template import into editable project.

7. **`cloud_sync`**:
   - Offline-first cloud sync status monitor (Local, Syncing, Synced).
   - Storage quota breakdown meter and versioned cloud project snapshots.

8. **`export`**:
   - Multi-format rendering engine with presets (480p, 720p, 1080p FHD, 4K UHD, 24/30/60 FPS).
   - Frame-by-frame 4-pass pipeline simulation with progress monitoring.
   - Export completion share sheet.

---

## 4. State Management (Riverpod)

- **`projectsNotifierProvider`**: Manages project list state, creation, deletion, and duplication.
- **`editorControllerProvider(project)`**: Auto-disposing state notifier for active project timeline state, playback, playhead, and editing operations.
- **`exportControllerProvider`**: State notifier streaming render pipeline progress.
- **`syncNotifierProvider`**: Manages cloud synchronization triggers.

---

## 5. Routing (GoRouter)

- `/` → `HomeScreen` (`RouteNames.home`)
- `/editor/:projectId` → `EditorScreen` (`RouteNames.editor`)
- `/store` → `AssetStoreScreen` (`RouteNames.store`)
- `/cloud` → `CloudSyncScreen` (`RouteNames.cloud`)
- `/export/:projectId` → `ExportScreen` (`RouteNames.export`)
