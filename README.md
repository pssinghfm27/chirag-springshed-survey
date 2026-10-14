# CHIRAG Springshed Survey

> A free, offline Android app for hydrogeological field surveys and recharge-zone mapping in the Indian Himalayan region. Built for the **Central Himalayan Rural Action Group (CHIRAG)** and shared openly for any NGO, researcher, or community working on springshed restoration.

[![Platform](https://img.shields.io/badge/platform-Android%208.0%2B-brightgreen)]()
[![Language](https://img.shields.io/badge/language-Kotlin-7f52ff)]()
[![License](https://img.shields.io/badge/license-MIT-blue)]()
[![Status](https://img.shields.io/badge/status-active-success)]()

---

## Why this exists

Across the Indian Himalayan region, the perennial springs that have sustained mountain communities for generations are drying up. Effective intervention through the **springshed management** approach requires identifying, for each individual spring, the recharge zone above it where intervention will actually work — pits dug in the wrong place don't help, trenches across the wrong slope don't recharge anything.

Identifying the recharge zone is fundamentally a structural-geology problem. Surveyors walk the slopes around each spring and measure the orientation of bedding planes, fractures, and faults at multiple points. Until now, NGO field teams have done this either with paper forms (slow, error-prone) or with proprietary apps like Rocklogger and FieldMove (₹2,000–₹5,000 per device, no offline support, no integration with NGO data workflows).

**This app closes that gap with a free, offline, customisable alternative built around CHIRAG's exact field protocol.**

---

## What it does

A surveyor walking up a hillside places the phone flat on a rock outcrop and the app automatically captures the rock plane's strike, dip direction, dip amount, latitude, longitude, and elevation. The surveyor only needs to manually record what kind of feature it is (bedding plane, fracture, spring, etc.), the rock type, and any remarks. Each spring becomes a project that can hold hundreds of observation points.

### Key features

- **Eleven-parameter survey** matching the standard CHIRAG hydrogeological observation form — 7 captured automatically from sensors, 4 entered manually.
- **Live compass dial** showing strike line and dip-direction arrow in real time, with sensor-quality indicators (red/yellow/green) so the surveyor knows when to trust a reading.
- **True-north correction** applied automatically using the World Magnetic Model — no manual declination math required.
- **On-device recharge-zone analysis** computes the up-dip bearing from all planar measurements and projects a probable recharge area in hectares.
- **Offline map view** renders survey hull, recharge fan, and spring marker without any internet or map-tile dependency.
- **CSV and Excel export** with three sheets (project metadata, all entries, computed analysis) shareable via WhatsApp, Gmail, USB, etc.
- **Illustrated phone-placement guide** built into the app to reduce surveyor training burden.
- **Five spring-type classification** — Depression, Fault, Fracture, Karst, Contact — with definitions in the app.

### What it deliberately is not

- Not a research-grade structural-geology instrument. Smartphone magnetometers are accurate to ±3–5° on a calibrated device — fine for intervention planning, not for academic publication. Cross-check with a Brunton compass on a sample of points if you need that level of rigour.
- Not a hydrogeological model. The recharge-zone calculation is an explicit first-order heuristic (60° up-dip fan, scaled to survey footprint) intended to direct surveyor attention. It assumes one dominant dip direction and ignores topography. Treat it as a hypothesis to test, not an answer.

---

## Get the app

### For surveyors / non-developers

Download the latest `.apk` from the [`apk/`](apk/) folder. Transfer to your Android phone and install. Requires Android 8.0 (API 26) or newer.

### For developers

Clone this repo, open in Android Studio (Hedgehog 2023.1.1 or newer), let Gradle sync, and build:

```
Build → Build Bundle(s) / APK(s) → Build APK(s)
```

The APK appears in `app/build/outputs/apk/debug/`. Detailed build instructions including troubleshooting are in the original `README` shipped with the source — if you hit problems, [open an issue](../../issues/new).

---

## How it works (briefly)

The phone's accelerometer, magnetometer, and gyroscope together let it know its full 3D orientation in real-world coordinates (East, North, Up). When laid flat on a rock plane with screen up, the phone's vertical axis becomes the outward normal to that plane. From that single vector the app derives:

- **Dip amount** — the angle between the plane and horizontal
- **Dip direction** — the compass bearing of steepest descent
- **Strike** — perpendicular to dip, by definition

All four azimuths are corrected from magnetic to true north using `GeomagneticField` evaluated at the live location and date. Sensor noise is smoothed with a low-pass filter applied to the **normal vector** rather than to the azimuth values directly — this is a non-obvious detail that, if got wrong, produces dramatic errors near magnetic north (because azimuths wrap at 360°).

For the recharge-zone estimate, the app computes the circular mean of all dip directions across planar entries in a project, reverses it 180° to get the up-dip bearing, and sweeps a 60°-wide triangular fan from the spring location with reach scaled to 1.5× the surveyed-area radius. Polygon area is computed via the shoelace formula on an equirectangular projection — accurate to <0.5% for survey extents under 5 km.

Full mathematical derivation is documented inline in `app/src/main/java/org/chirag/springshed/geology/GeologicalMath.kt`.

---

## Tech stack

| Aspect | Choice |
|---|---|
| Language | Kotlin 2.0.21 |
| UI | Jetpack Compose with Material 3 |
| Architecture | MVVM |
| Database | Room (SQLite) |
| Excel export | Apache POI 5.2.5 |
| Location | Google Play Services (FusedLocationProvider) |
| Min Android | 8.0 (API 26) |
| Approx. APK size | ~9 MB |

**Offline-first by design.** No internet permission. The app cannot send data anywhere — it physically can't phone home. All survey data stays on the device until the surveyor explicitly exports and shares.

---

## Project context

This app was built during a summer internship at CHIRAG (Central Himalayan Rural Action Group) in Uttarakhand, between April and June 2026, as part of the MBA (Forestry Management) programme at the Indian Institute of Forest Management, Bhopal. The internship's broader theme — *Building Common Interpretation Around Water and Forest in the Himalayan Context* — produced several interconnected deliverables; this app is one of them.

CHIRAG has worked across rural communities in Nainital, Almora, Bageshwar, and Champawat districts of Uttarakhand since 1986 on natural resource management, rural health, education, and sustainable livelihoods. Their springshed programme has inventoried hundreds of springs and facilitated community-led recharge interventions including contour trenches, recharge pits, and chal-khals.

Learn more: [chirag.org](https://chirag.org)

---

## Field validation

- Validated against a Brunton compass-clinometer with **44 paired readings at Raghunath Mandir Spring, Bageshwar**.
- GPS: 5-sample inverse-variance weighted fix, typically ±3-10 m, sub-5 m common under open canopy.
- Magnetic declination and field-posture dip corrections applied automatically.

## Documentation

- [Technical report](docs/TECHNICAL_REPORT.md) - sensor pipeline, data model, exports, roadmap
- [User manual](docs/USER_MANUAL.md) - field procedure for surveyors
- [`apk/`](apk/) - signed Springshed Survey v1.0.0, plus two companion field apps built in the same programme: **Intervention Recorder** (offline mapping of trenches, pits and other recharge works) and **RockBed3D Visualizer** (3D strike/dip visualisation)

Related: [springshed-qgis-plugins](https://github.com/pssinghfm27/springshed-qgis-plugins) turns this app's exports into recharge-zone maps in QGIS.

---

## Contributing

Issues, suggestions, and pull requests are welcome — particularly from people doing similar springshed or hydrogeological work in the Himalayan region.

Useful contributions include:
- **Field validation data** — paired Brunton-vs-app readings from any geographic context. This is the single most useful thing to add.
- **Translations** — the UI is currently English-only. Hindi and Kumaoni translations are high priority. Other regional languages welcome.
- **Bug reports** — especially with full Logcat output and the phone make/model.
- **Feature ideas** — open an issue to discuss before building anything large.

---

## Licence

MIT. Use it, modify it, ship your own variant, sell it if you can find a buyer — just keep the copyright notice. See `LICENSE` for the boring legal version.

---

## Credits

Built by **Prahlad Pratap Singh** (MBA-FM 2025–27, IIFM Bhopal) during summer internship at CHIRAG.

Thanks to the CHIRAG team in Simyal and the field stations, fellow interns Riviresh Mishra (IoT/water-quality work), Urvashi Patil, Nivedita and Gaurav Kumar, and to the village communities who tested early builds in the field.

Built with help from Anthropic's Claude.

