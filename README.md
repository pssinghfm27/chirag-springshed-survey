# CHIRAG Springshed — Android Field Survey App

A professional Kotlin + Jetpack Compose app for CHIRAG's springshed management programme. Replaces Rocklogger / GeoKit for hydrogeological surveys around Himalayan springs, with automatic capture of GPS (lat, lon, elevation), strike, dip direction, and dip amount, plus predicted recharge-zone mapping.

---

## Features

- **One project per spring.** Named after the spring, stores up to thousands of entries.
- **Eleven-parameter field entry** matching the CHIRAG survey protocol:
  1. Latitude *(auto)*
  2. Longitude *(auto)*
  3. Elevation *(auto)*
  4. Code — Bedding Plane / Folding Plane / Spring / Deposition / Fracture *(manual)*
  5. Strike North *(auto)*
  6. Strike South *(auto)*
  7. Dip Direction *(auto)*
  8. Dip Amount *(auto)*
  9. Rock Type *(manual)*
  10. Remarks *(manual)*
  11. Spring Type — Depression / Fault / Fracture / Karst / Contact *(manual, only for Spring entries)*
- **Live sensor HUD** with compass dial, strike line, dip arrow, GPS quality, compass accuracy, magnetic-declination chip.
- **Capture-then-save** workflow: freeze a reading, fill in manual fields, save.
- **Offline recharge-zone map** drawn with Canvas — survey hull, recharge fan, up-dip arrow, spring marker, scale bar.
- **CSV and XLSX export** via Apache POI. The XLSX has three sheets: Project metadata, Survey Entries, Analysis summary.
- **CHIRAG branding**: custom vector logo (leaf + water droplet), forest-green and Himalayan-sky palette, adaptive launcher icon.
- **Offline-first, no cloud.** All data stays on device in a Room database.

---

## Build steps

### 1. Prerequisites

- Android Studio **Hedgehog (2023.1.1)** or newer.
- JDK 17 (Android Studio ships one; you don't need to install separately).

### 2. Generate the Gradle wrapper (one-time)

This repo ships without `gradle/wrapper/gradle-wrapper.jar`, `gradlew`, and `gradlew.bat`. Any of these paths will generate them:

**Option A — Android Studio auto-fix (easiest)**
1. `File → Open` and pick the project folder.
2. Studio shows a yellow banner: *"Gradle wrapper is missing. Use default wrapper?"* — click **OK** / **Fix**.
3. The sync runs and the wrapper appears.

**Option B — from a machine with Gradle ≥ 8.7 installed**
```
gradle wrapper --gradle-version 8.7 --distribution-type bin
```

**Option C — copy from any Android project** you already have. Any Gradle 8.x wrapper works.

### 3. Build

- Open in Android Studio, wait for sync (2–4 min, downloads POI, Compose, Room, etc.).
- Build a debug APK:
  - Menu: `Build → Build Bundle(s) / APK(s) → Build APK(s)`.
  - Output: `app/build/outputs/apk/debug/app-debug.apk`
- Build a release APK (requires a signing keystore):
  - Menu: `Build → Generate Signed Bundle / APK → APK → release`.
  - Output: `app/build/outputs/apk/release/app-release.apk`

### 4. Install

- Plug in an Android phone with USB debugging on, then: `adb install app/build/outputs/apk/debug/app-debug.apk`
- Or just copy the APK to the phone and tap to install.

---

## Folder map

```
app/src/main/
├── AndroidManifest.xml
├── java/org/chirag/springshed/
│   ├── SpringshedApp.kt              # Application class & service locator
│   ├── MainActivity.kt                # Single activity + Compose host
│   ├── data/
│   │   ├── db/                        # Room database, DAOs
│   │   ├── entities/                  # Project, SurveyEntry, SurveyCode, SpringType
│   │   ├── repository/                # SpringshedRepository
│   │   └── export/                    # CsvExporter, XlsxExporter
│   ├── sensors/
│   │   ├── LocationTracker.kt         # FusedLocationProvider + GeomagneticField
│   │   └── OrientationTracker.kt      # Sensor fusion + low-pass filter
│   ├── geology/
│   │   ├── GeologicalMath.kt          # Strike/dip from rotation matrix (documented)
│   │   ├── GeoArea.kt                 # Haversine, projection, convex hull, area
│   │   └── RechargeZoneAnalyzer.kt    # Up-dip fan heuristic
│   ├── navigation/
│   │   └── SpringshedNavGraph.kt
│   ├── ui/
│   │   ├── theme/                     # Theme.kt, Typography.kt
│   │   ├── components/                # Branding, CompassDial, ReadoutRow
│   │   ├── screens/                   # 6 screens (see below)
│   │   └── viewmodels/                # MVVM layer + factory
│   └── util/Fmt.kt                    # Shared format helpers
└── res/
    ├── drawable/                      # Launcher foreground/background vectors
    ├── mipmap-*/                      # Launcher PNGs (5 densities) + adaptive XML
    ├── values/                        # strings, colors, themes
    ├── values-night/                  # Dark-mode theme
    └── xml/                           # backup_rules, data_extraction_rules, file_paths
```

### Screens

| Route | Screen | Purpose |
|---|---|---|
| `home` | HomeScreen | CHIRAG header, list of spring projects, new-project FAB, guide link |
| `new_project` | NewProjectScreen | Create a spring project with name, village, district, state, surveyor, notes |
| `project/{id}` | ProjectDetailScreen | Entries list, analysis summary card, CSV/XLSX export menu |
| `project/{id}/new_entry` | NewEntryScreen | Live sensor HUD, capture, code chips, rock type, remarks, spring-type chips |
| `project/{id}/recharge` | RechargeMapScreen | Offline canvas map of hull + fan + spring with scale bar |
| `phone_guide` | PhoneGuideScreen | Illustrated guide for placing the phone on rock + water-flow diagram |

---

## How the math works

### Strike and dip

Android's `SensorManager.getRotationMatrix` (or `getRotationMatrixFromVector`) produces a 3×3 matrix that transforms device coordinates to world coordinates `(East, North, Up)`. Lay the phone screen-up on the rock plane — the phone's +Z axis is then the plane's outward normal **n**:

```
n = R · (0, 0, 1)ᵀ = (R[2], R[5], R[8])
```

From **n** we read:

- **Dip amount** = `acos(R[8])` — the angle between the plane and horizontal.
- **Dip direction** = azimuth of `-n_horizontal`, since the horizontal part of **n** points up-dip.
- **Strike North** = `dip_direction − 90°`, **Strike South** = `strike_north + 180°`.

All four azimuths are corrected from magnetic to true north using `GeomagneticField.getDeclination()` evaluated at the live fix's lat/lon/altitude/time.

See `geology/GeologicalMath.kt` for the full derivation with edge cases (upside-down phone, horizontal plane).

### Recharge-zone inference

Groundwater flows down-dip through bedding or fracture planes and emerges where the water-bearing layer is cut by the hillside. The recharge zone therefore lies **up-dip** of the spring.

`RechargeZoneAnalyzer`:

1. Anchors on the spring's mean location (fallback: centroid of all entries).
2. Computes the circular mean of all dip directions across plane entries.
3. Reverses it to get the up-dip bearing.
4. Sweeps a 60°-wide triangular fan from the spring in the up-dip direction, with reach scaled to the survey footprint (at least 150 m).
5. Computes the fan area (shoelace, m²/ha) and the convex-hull area of all survey points.

This is an explicit first-order heuristic, not a hydrogeological model. It assumes one dominant dip direction and ignores topography and surface divides. Meant to point the surveyor's attention, not replace a real groundwater study.

---

## Field calibration checklist (print and hand to surveyors)

- **Calibrate the compass before every site.** Move the phone in a figure-8 for ~10 seconds. The app shows compass quality (green / yellow / red). If it stays red, the area may have too much magnetic interference (near iron ore, rebar, or transmission lines) — record a note and flag the reading.
- **Remove metal clipboards, knives, real compasses, belt buckles** from within 30 cm of the phone before capturing. They pull the magnetometer.
- **Wait for GPS to reach ±5 m or better** before tapping Capture. Under heavy canopy you may have to wait 30–60 s or walk into a clearer patch.
- **Phone placement:** screen up, flat against the plane, long edge along the dip line (the steepest line down the plane). Use a notebook as a levelling shim on rough rock.
- **For Spring entries:** put the phone right at the discharge point. Select the correct spring type; if unsure, use Remarks to note what you see and mark as the best-guess type.
- **Spot-check with a Brunton every ~20 readings.** Expect phone readings to agree within ±3–5°. If you see worse, recalibrate and note the discrepancy.

---

## Exports

- **CSV**: 23-column, RFC-4180-safe. Header row: serial, project metadata, timestamp, all 11 parameters, magnetic declination, spring-type label.
- **XLSX**: three sheets. "Project" has metadata. "Survey Entries" has all 11 parameters with frozen header row, number formats, borders, and a dark-green header style. "Analysis" has the computed recharge summary: up-dip bearing, mean dip amount, fan area (m², ha), hull area (m², ha), fan reach (m), plane count.

Both are written to `app_files/exports/` and shared via `FileProvider` to any app (Gmail, Drive, Telegram, etc.).

---

## Roadmap / what this app does not yet do

- **iOS build.** The project is Android-only as requested. Porting to iOS would mean a SwiftUI rewrite with CoreLocation + CoreMotion; the geological and recharge-zone math in `geology/` is pure Kotlin with no Android dependencies and would translate in a few hundred lines of Swift. A Kotlin Multiplatform approach would let the `geology` module be shared — worth considering before the iOS port.
- **Basemap tiles.** The recharge map is a clean offline canvas render. If you want a satellite / topo basemap, add `com.mapbox.maps:android` or `osmdroid` and layer the polygons on top; the `fanPolygonLatLon` and `surveyHullLatLon` fields on `RechargeZoneAnalyzer.Result` are already in lat/lng.
- **Photos per entry.** Not included. Easy to add: a `photoPath: String?` column on `SurveyEntry`, a camera intent in `NewEntryScreen`, and the XLSX exporter can embed images via POI's `Drawing.createPicture`.
- **Project backup / restore as ZIP.** The Room DB is auto-backed up per `backup_rules.xml`; a user-triggered "Backup all projects to ZIP" would be a ~40-line addition.
- **Digital-compass sensor accuracy.** We already read and surface this; consider adding a mandatory figure-8 calibration screen before the first capture if compass quality is `UNRELIABLE`.

---

## Licence and attribution

Built for CHIRAG (Central Himalayan Rural Action Group). Uses:

- Apache POI 5.2.5 (Apache 2.0) — Excel export
- AndroidX Room, Compose, Lifecycle, DataStore (Apache 2.0)
- Google Play Services Location (proprietary, free)
- Accompanist Permissions (Apache 2.0)
- Kotlinx Coroutines + Serialization (Apache 2.0)

No web or telemetry calls. All data stays on device.
