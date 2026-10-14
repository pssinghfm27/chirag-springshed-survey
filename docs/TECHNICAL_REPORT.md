# CHIRAG Springshed — Field Hydrogeology App

**Internship report · Summer 2026**
**Author**: Prahlad Pratap Singh · IIFM Bhopal
**Host organisation**: CHIRAG (Central Himalayan Rural Action Group)
**Repository**: `chirag_springshed/`
**Release artefact**: `chirag-springshed-release.apk` (15 MB, signed v1.0.0, minSdk 26, target 34)

---

## 1. Context & Problem Statement

CHIRAG's field surveyors collect hydrogeological observations in deep-forest spring-shed terrain across Uttarakhand for spring-rejuvenation interventions. Pre-existing workflow:

1. Record GPS, slope, strike/dip, rock type by hand in a notebook.
2. Re-key into an Excel template (`Lakhmar Village Intervention Survey.xlsx`) back at base.
3. Manually plot in Google Earth Pro by typing coordinates into a KML file and drawing T-shaped strike/dip symbols by hand on each placemark.

This workflow has three failure modes the app eliminates:

| Pain point | Mechanism in the app |
|---|---|
| No connectivity in the field | Offline-first Room DB; zero network calls during capture |
| Manual transcription errors | Sensors auto-fill 8 of the 11 parameters |
| Hours of manual KML drawing | One-tap export emits geological T-symbols at true ground orientation |

---

## 2. Architecture Overview

```
app/src/main/java/org/chirag/springshed/
├── data/
│   ├── db/                  Room database (AppDatabase, Daos)
│   ├── entities/            Project, SurveyEntry, enums (SurveyCode, SpringType)
│   ├── repository/          SpringshedRepository (single source of truth)
│   └── export/              CsvExporter, KmlExporter, KmzExporter
├── sensors/
│   ├── LocationTracker      FusedLocationProvider + best-fix averaging
│   └── OrientationTracker   Accelerometer + magnetometer + rotation-vector fusion
├── geology/
│   ├── GeologicalMath       Rotation-matrix → strike/dip; circular mean
│   └── RechargeZoneAnalyzer Plane-fitting + recharge-fan prediction
├── ui/
│   ├── theme/               Material 3 + CHIRAG brand tokens
│   ├── components/          GpsChip, ChiragField, SectionHeader, CompassDial
│   ├── screens/             Home, NewProject, ProjectDetail, NewEntry, RechargeMap
│   └── viewmodels/          Per-screen AndroidViewModels
└── navigation/              NavGraph (Jetpack Compose Navigation)
```

**Patterns**
- MVVM with `StateFlow`/`collectAsState`
- Sensor streams as cold `Flow<T>` via `callbackFlow`
- Pure Kotlin geology math layer (unit-testable in isolation)

---

## 3. Data Model

### `Project`
Project metadata: name, village, district, state, surveyor, notes, timestamps.

### `SurveyEntry` — one observation point, 11 parameters

| # | Field | Source |
|---|---|---|
| 1 | Latitude (°) | GPS (auto, weighted-averaged) |
| 2 | Longitude (°) | GPS (auto, weighted-averaged) |
| 3 | Elevation (m) | GPS (auto) |
| 4 | Survey code | Manual (Bedding Plane, Folding Plane, Spring, Deposition, Fracture) |
| 5 | Strike North (°) | Sensors → circular mean of burst |
| 6 | Strike South (°) | Derived (= N + 180°) |
| 7 | Dip direction (°) | Sensors → circular mean of burst |
| 8 | Dip amount (°) | Sensors → corrected (`90° − raw`) |
| 9 | Rock type | Manual |
| 10 | Remarks | Manual |
| 11 | Spring type | Manual (only when code = Spring; 5 sub-types) |

Plus: horizontal/vertical GPS accuracy, magnetic declination applied, captured-at timestamp.

---

## 4. Sensor Pipeline

### 4.1 GPS — `LocationTracker`

**Why averaging matters.** A single consumer-phone GNSS fix has 5–30 m noise even with a clean sky. The app's `bestFix()` method addresses this:

```kotlin
suspend fun bestFix(
    targetSamples: Int = 5,
    acceptAccuracyM: Float = 10f,
    timeoutMs: Long = 12_000L
): LocationFix?
```

Algorithm:
1. Request `PRIORITY_HIGH_ACCURACY` updates at 800 ms intervals.
2. Discard cached fixes (`elapsedRealtimeNanos` age > 5 s).
3. Discard fixes worse than 10 m horizontal accuracy.
4. Collect up to 5 acceptable fixes within 12 s.
5. Reduce via **inverse-variance weighting**: weight = 1 / accuracy². Better fixes dominate the mean.
6. Combined accuracy ≈ `max(best × 0.7, 1/√Σw)` — never claims better than the best single sample.

Result: ±3–10 m fixes typical, sub-5 m common in open canopy.

### 4.2 Orientation — `OrientationTracker`

Reads `TYPE_ACCELEROMETER` + `TYPE_MAGNETIC_FIELD` (with `TYPE_ROTATION_VECTOR` preferred when available — already includes gyro fusion). Pipeline:

1. Build 3×3 rotation matrix via `SensorManager.getRotationMatrix`.
2. Low-pass filter the world-frame **normal vector** (E, N, U components) — *not* the azimuth, because azimuths wrap at 360° and would filter incorrectly at the wrap point.
3. Feed filtered normal into `GeologicalMath.fromRotationMatrix(decl)`.
4. **Field-practice dip correction**: surveyors hold the phone with its long edge resting on the bedding plane (clinometer-card style) rather than face-flat. In that posture the raw pitch measures the complement of the true geological dip. Applied at sensor output as `dip = 90° − raw`, so dashboard, saved entries, and all exports stay consistent.
5. Magnetic declination from `GeomagneticField` converts magnetic → true north.

### 4.3 Capture flow — `NewEntryViewModel.capture()`

Parallel coroutines:
- **GPS burst** → `bestFix()` (above).
- **Orientation burst** → 2 s of `OrientationSample` collected.

Orientation samples are then reduced:
- Strike-N and dip-direction: `GeologicalMath.circularMean()` — converts each angle to a unit vector `(cos θ, sin θ)`, sums, then `atan2` of the resultant. This is the **only** statistically correct way to average angles that wrap.
- Dip amount: arithmetic mean (does not wrap).

Both reductions feed `_frozen`, which the UI displays before save.

---

## 5. Geology Math

`GeologicalMath` is pure Kotlin, no Android dependencies.

### 5.1 Strike & dip from rotation matrix

For a phone laid face-up on a rock plane, the +Z device axis is the plane's outward normal. In world frame:

```
n = R · (0,0,1)ᵀ = (R[2], R[5], R[8])  = (nE, nN, nU)

Dip amount  δ = acos(nU)                      [0°…90°]
Anti-dip az  = atan2(nE, nN)                  [E/N components → bearing from N]
Dip direction = (anti-dip + 180°) mod 360°
Strike (N)    = (dip-dir − 90°) mod 360°
Strike (S)    = strike-N + 180°
```

Then declination is added to all azimuths (magnetic → true).

### 5.2 Recharge zone analysis — `RechargeZoneAnalyzer`

Given N plane observations + 1 spring point:
1. Project all entries to local metric coordinates (equirectangular around spring anchor).
2. Compute **mean up-dip direction** via circular mean of all `dipDir + 180°`.
3. Build a **convex hull** of survey points (Andrew's monotone-chain).
4. Predict a recharge-fan polygon: anchor at spring, opens in up-dip direction with apex angle proportional to dip variance, length scaled by mean dip amount.
5. Compute hull area (shoelace formula) and predicted fan area, in m² and hectares.

---

## 6. UI & Design System

### 6.1 Brand tokens — from `CHIRAG Field Survey Design System (1).zip`

Implemented in `ui/theme/`:

| Token group | File | Notes |
|---|---|---|
| Material 3 colour scheme | `Theme.kt` | Primary `#BB1622` (CHIRAG red, sampled from the diya-lamp logo); secondary brown (soil); tertiary green (recharge); 11 intervention-typology accent colours; 3 zone accents |
| Typography | `Typography.kt` | Roboto (UI), Noto Serif (brand display — has Devanagari coverage), Roboto Mono (GPS readouts). Downloadable via Google Fonts provider with the gms-fonts cert array |
| Shape | `Shape.kt` | M3 shapes 4/8/12/16/28 dp |

### 6.2 Reusable composables — `ui/components/`

- **`GpsChip`** — pill chip; green when locked, amber while searching; renders `GPS ±X m` in mono.
- **`ChiragField`** — outlined input with floating label, mono variant for coordinate fields.
- **`SectionHeader`** — emoji + uppercase tracked label, zone-accent coloured.
- **`ChiragChip`** — selectable filter chip with check leading icon.
- **`CompassDial`** — Canvas-rendered compass showing strike line + dip-direction arrow.
- **`ChiragLogoMark`**, **`ChiragBrandHeader`** — vector-drawn brand identity (no asset files needed).

### 6.3 Screens

| Screen | Purpose |
|---|---|
| `HomeScreen` | Project list, hero brand header, FAB to create a project, link to phone-guide |
| `NewProjectScreen` | Project metadata form |
| `ProjectDetailScreen` | Entry list grouped by survey code; export menu (CSV / KML / KMZ); delete entry confirmations |
| `NewEntryScreen` | Live GPS + sensor readouts; Capture button → review frozen values → Save; manual overrides for each of the 11 parameters |
| `RechargeMapScreen` | Canvas-rendered map: survey points, hull, predicted recharge fan, spring marker; legend; analysis stats |
| `PhoneGuideScreen` | Animated illustrations explaining how to hold the phone on the rock |

---

## 7. Exports

All exports run on `Dispatchers.IO` inside `runCatching`. Errors are logged to `Log.e("Export", …)` and surfaced as Toasts (never crash the app).

### 7.1 CSV — `CsvExporter`

- UTF-8 with BOM (so Excel on Windows auto-detects encoding).
- Header row mirrors the original Excel column order plus accuracy & timestamps.
- Coordinates: 7 decimal places (≈1 cm precision); angles: 2 dp.
- Embedded commas, quotes, newlines properly escaped (RFC 4180).

### 7.2 KML 2.2 — `KmlExporter`

Opens cleanly in Google Earth Pro, QGIS, Garmin BaseCamp, any standards-compliant GIS.

- One `<Folder>` per survey code (groups markers in the GE sidebar).
- Per-code styled `<Placemark>` with coloured Google paddle icons.
- `<BalloonStyle>` shows formatted HTML on click: capture time, accuracy, strike/dip, rock type, remarks.
- `<Schema>` + `<ExtendedData><SchemaData>` exposes all 15 typed fields for GIS analysis.
- `<TimeStamp>` enables Google Earth's time-slider playback.
- Altitude: `absolute` mode using GPS-measured elevation.

**Geological T-symbol rendering** (the headline feature):

For each plane observation (Bedding, Folding, Fracture with dip ≥ 0.5°), the exporter emits two extra `LineString` placemarks:

- **Strike bar** — orange, ~16 m on the ground, centered on the point, drawn along the strike azimuth.
- **Dip stem** — blue, ~6 m, drawn from the point outward along the dip-direction azimuth.

Together they form the geological ⊢ symbol at true ground orientation — replacing the manual KML drawing step that previously took hours after every survey.

Coordinate offsets computed correctly for the latitude:
```
dLat = m · cos(az) / 111320
dLon = m · sin(az) / (111320 · cos(lat))
```

### 7.3 KMZ — `KmzExporter`

ZIP-compressed KML containing `doc.kml` at the archive root (Google Earth convention). Smaller and single-file-shareable; the same T-symbol output, just packaged.

---

## 8. Persistence

- **Room 2.6.1** with KSP code generation.
- 2 entities (`Project`, `SurveyEntry`) joined by `projectId` foreign key with cascade delete.
- `Flow<List<SurveyEntry>>` observed in viewmodels for reactive UI.
- Auto-backup config (`backup_rules.xml`, `data_extraction_rules.xml`) explicitly includes the DB and excludes the `exports/` cache.

---

## 9. Build & Distribution

### 9.1 Tooling

- AGP 8.x, Kotlin 1.9.x, Compose BOM 2024.09.03, JDK 17 (Android Studio JBR).
- KSP for Room annotation processing.
- Core library desugaring (`desugar_jdk_libs` 2.1.2) for `java.time` on API < 26 (unused but kept).

### 9.2 Release signing

A self-signed keystore (`chirag-release.jks`, RSA-2048, SHA-384, 30-year validity) was generated and wired into `signingConfigs.release`. The same keystore must be used for every update of the same app — losing it forces users to uninstall before installing a new build.

### 9.3 ProGuard / R8

`isMinifyEnabled = true` with custom keep rules for:
- Room generated classes
- Kotlinx serialization
- Entity classes (`org.chirag.springshed.data.entities.*`)

### 9.4 APK

| Variant | Size | Purpose |
|---|---|---|
| Debug | ~30 MB | Development on `org.chirag.springshed.debug` |
| Release | 15 MB | Signed, minified; `org.chirag.springshed` |

The 15 MB is dominated by `material-icons-extended` (~7 MB of vector drawables that R8 can't shrink because icon usage looks reflective). Acceptable trade-off for the developer-experience gain.

---

## 10. Field-quality Decisions

| Decision | Rationale |
|---|---|
| `withContext(Dispatchers.IO)` for every export | POI workbook generation and KML serialization can take 100s of ms on large projects — main-thread blocks were causing ANRs |
| `runCatching` + Toast on every export | Field surveyors can't see logcat; the toast tells them what failed |
| Inverse-variance GPS weighting | Equal weighting lets one bad fix poison the average; weighting by 1/σ² is the maximum-likelihood estimator |
| Circular mean for azimuths | Arithmetic mean of 350°, 10° = 180° (wrong). Circular mean = 0° (correct) |
| Dip correction at sensor output | Applying it later would mean four code paths (UI, save, CSV, KML, KMZ) must remember to apply it — a bug surface. One correction at the source guarantees consistency |
| Low-pass on the normal vector, not the angle | Same wrap-around argument as circular mean |
| UTF-8 BOM in CSV | Excel on Windows treats BOM-less UTF-8 as Windows-1252 and renders garbled accents |
| `absolute` altitude in KML | `relativeToGround` is what hand-drawn KMLs use, but it sits planar symbols on uneven terrain incorrectly. `absolute` + real GPS elevation places them at the actual rock face |

---

## 11. Capabilities Summary

- **Capture**: high-accuracy GPS (5-sample inverse-variance weighted average, ±3–10 m) + phone-as-clinometer for strike, dip direction, dip amount with magnetic-declination correction and field-posture dip correction.
- **Record**: 11 hydrogeological parameters per observation point; 5 distinct survey codes; 5 spring sub-types.
- **Analyze**: auto-computed mean up-dip direction, surveyed convex hull, predicted recharge fan polygon with area in m²/ha.
- **Export**: CSV (Excel-compatible UTF-8), KML 2.2 with per-code styled markers, geological T-symbols at true ground orientation, schema'd extended data; KMZ companion.
- **Offline**: zero network calls during capture; all data in Room DB on device.
- **Shareable**: 15 MB signed APK installs on any Android 8.0+ device; ready for WhatsApp distribution to the field team.

---

## 12. Future Scope

- **Raw GNSS** via `GnssMeasurementsEvent` for carrier-phase smoothing — could push accuracy under 2 m on phones with dual-frequency GNSS (Pixel 5+).
- **External GNSS receiver support** over Bluetooth (Bad Elf, Garmin GLO, u-blox) for sub-metre work.
- **Offline base maps** via MBTiles + OSMDroid for in-the-field map context.
- **KML import** — load existing manual KMLs to extend prior surveys.
- **Co-pilot guidance** — voice cues during capture ("hold steady…", "good fix") for solo surveyors.

---

## 13. File Index (key sources)

| File | Purpose |
|---|---|
| `app/build.gradle.kts` | AGP config, dependencies, signing |
| `app/proguard-rules.pro` | R8 keep rules |
| `app/src/main/java/org/chirag/springshed/sensors/LocationTracker.kt` | GPS averaging |
| `app/src/main/java/org/chirag/springshed/sensors/OrientationTracker.kt` | Sensor fusion + dip correction |
| `app/src/main/java/org/chirag/springshed/geology/GeologicalMath.kt` | Pure math (testable) |
| `app/src/main/java/org/chirag/springshed/geology/RechargeZoneAnalyzer.kt` | Hull + fan prediction |
| `app/src/main/java/org/chirag/springshed/data/export/KmlExporter.kt` | KML 2.2 + T-symbols |
| `app/src/main/java/org/chirag/springshed/data/export/KmzExporter.kt` | ZIP-wrapped KML |
| `app/src/main/java/org/chirag/springshed/data/export/CsvExporter.kt` | Excel-friendly CSV |
| `app/src/main/java/org/chirag/springshed/ui/viewmodels/ViewModels.kt` | Capture orchestration, parallel GPS/orientation bursts |
| `app/src/main/java/org/chirag/springshed/ui/theme/{Theme,Typography,Shape}.kt` | Design tokens |
| `app/src/main/java/org/chirag/springshed/ui/components/DesignComponents.kt` | GpsChip, ChiragField, SectionHeader, ChiragChip |

---

*Report generated at end of release v1.0.0 cut. Keystore stored at `chirag_springshed/chirag-release.jks` — must be retained for future updates.*
