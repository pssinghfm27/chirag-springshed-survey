# CHIRAG Springshed — Field User Manual

**App version**: v1.0.0 (release build, 15 MB)
**Works on**: Android 8.0 (Oreo) or newer
**Internet**: Not needed in the field. All data stays on the phone until you export.

---

## 1. Install

1. Copy `chirag-springshed-release.apk` to the phone (WhatsApp, USB, or email).
2. Tap the file → **Install**. If Android warns about "unknown source", tap **Settings → Allow from this source** then return and install.
3. Open the app. The first launch will ask for **Location** permission — tap **While using the app**.

---

## 2. Home Screen

The first screen you see after launch.

![Home screen](screenshots/01-home.png)

What's on it:

- **Springshed Survey** brand header at the top.
- **How to hold the phone** — opens a quick visual guide on phone placement. Read this once before your first survey.
- **Projects** — list of every spring you've started a survey for. Tap the **›** chevron on the right to open one; tap the **🗑** icon to delete.
- **New Spring** button (bottom-right) — creates a brand-new project.

---

## 3. How to Hold the Phone (one-time read)

Tap **How to hold the phone** on the home screen.

![Phone guide](screenshots/02-phoneguide.png)

The golden rule:

> **Lay the phone FLAT on the rock with the screen facing up. Align the long edge along the steepest line of the plane. Hold still until the readings stop drifting, then tap Capture.**

Any tilt of the phone away from the rock surface = wrong strike/dip readings. Treat the phone like a Brunton compass card.

Below that, the second figure shows how groundwater flows from the recharge zone (uphill) through the rock to the spring (downhill) — this is the geological model the app uses to predict recharge fans.

---

## 4. Create a New Project

From the home screen tap **+ New Spring**.

![New project](screenshots/07-newproject.png)

Fill in:

| Field | Required? | Notes |
|---|---|---|
| **Spring name** | ✅ Yes | The local name of the spring (e.g. *Wahkrem*, *Madandemkhlieng*). This becomes the filename for every export. |
| Village | Optional | Free text. |
| District | Optional | Free text. |
| State | Optional | Free text. |
| Surveyor name | Optional | Goes into the export metadata. |
| Notes | Optional | Any context — landowner, weather, access notes. |

Tap **Create project**. You go straight to the project detail screen.

---

## 5. Project Detail — Add Observations

![Project detail](screenshots/03-projectdetail.png)

You'll see three things:

### A. Recharge analysis card (auto-computed)
- **Up-dip** — bearing of the predicted recharge zone (e.g. *36.7° (NE)*).
- **Dip** — mean dip angle of all plane observations.
- **Recharge** — area of the predicted recharge fan in hectares.
- **Hull** — area of the surveyed convex hull.
- Number of plane entries used.
- **Open Recharge-Zone Map** — visualises all of this graphically (see §7).

The card updates automatically as you add more plane observations.

### B. Field entries list
Each row shows the entry number, observation type (Spring / Bedding Plane / Folding Plane / Fracture / Deposition), coordinates, elevation, and strike/dip if applicable. Tap **🗑** to delete an entry.

### C. **+ Add Entry** button (bottom-right)
Opens the capture screen (next section).

The top bar has two extra icons:
- **?** — quick help.
- **↓** (download) — export menu (see §8).

---

## 6. Capture a Field Observation

Tap **+ Add Entry** on the project detail screen.

![New entry](screenshots/06-newentry.png)

### Live reading panel (top)
- **Compass dial** — shows the current strike (red line through N–S) and dip direction (red arrow). Watch this stabilise before tapping Capture.
- **Lat / Lon / Elev** — current GPS position.
- **Strike N / Strike S** — strike azimuth, true north.
- **Dip Dir** — dip-direction bearing (e.g. *223° (SW)*).
- **Dip Amt** — dip amount in degrees. **Already corrected** — see §10.

### Status chips
- **Compass: Reliable / Unreliable** — if Unreliable, wave the phone in a figure-8 motion away from metal to recalibrate.
- **GPS: ±X m** — current accuracy. Wait for a green chip with ≤10 m before capturing.
- **Decl: ±X°** — magnetic declination automatically applied to all azimuths.

### Capture button
Tap **Capture** when the readings are steady. Behind the scenes the app then:
1. Runs a **2-second GPS burst** (5 fresh fixes, inverse-variance weighted average).
2. Runs a **2-second orientation burst** (circular-mean of strike and dip-direction; arithmetic mean of dip amount).
3. Freezes those averaged values so you can review them.

You'll see "Capturing…" while this runs. **Hold the phone steady the whole time.**

### Form fields (below)

**Observation code** — pick exactly one:

| Code | When to use |
|---|---|
| **Bedding Plane (sedimentary)** | Layered sedimentary rock — sandstone, shale, limestone bedding |
| **Folding Plane (non-sedimentary)** | Foliation in metamorphic rock, or fold limb planes |
| **Spring** | The actual water-emergence point. Triggers the Spring Type sub-field |
| **Deposition** | Boulder bed, scree, debris — any deposited surface |
| **Fracture** | Joint or fracture in hard rock |

**Spring sub-type** (only shown when code = Spring) — Depression / Fault / Fracture / Karst / Contact spring.

**Rock type** — free text (e.g. *sandstone*, *quartzite*, *gneiss*).

**Remarks** — anything worth noting.

Tap **Save** at the bottom. You're returned to the project detail screen and the new entry appears in the list.

---

## 7. Recharge-Zone Map

From the project detail screen tap **Open Recharge-Zone Map**.

![Recharge map](screenshots/05-rechargemap.png)

### Summary panel (top)
- **Spring latitude / longitude** — exact coordinates of your Spring entry.
- **Mean dip dir** — average direction the rock dips toward (e.g. *216.7° (SW)*).
- **Up-dip → recharge** — opposite direction; this is where rain enters the rock system.
- **Mean dip amount** — average dip angle across all planes.
- **Predicted recharge** — area of the green fan polygon in hectares + m².
- **Survey hull area** — area enclosed by your observation points.
- **Fan reach** — how far up-slope the recharge zone extends.
- **Plane entries used** — how many bedding/folding/fracture entries fed the model. Aim for **≥3** for a meaningful prediction.

### Visualisation
- **Green polygon** = predicted recharge fan (where the water comes from).
- **Brown polygon** = convex hull of all your observation points.
- **Blue dot** = spring location.
- **Grey dots** = plane observations.
- **Red arrow** = mean up-dip direction.
- Scale bar at the bottom-left in metres.

Tap **←** to return to the project.

---

## 8. Export Data

On the project detail screen tap the **↓ (download)** icon at the top-right.

![Export menu](screenshots/04-exportmenu.png)

Three formats are offered:

| Format | When to use | Opens in |
|---|---|---|
| **CSV** | For Excel / Google Sheets / data analysis | Excel, LibreOffice, R, Python pandas |
| **KML** (Google Earth) | For visualisation, reports, manual edits | **Google Earth Pro**, QGIS, Garmin BaseCamp |
| **KMZ** (compact) | Same as KML but zipped — single file, smaller, easier to WhatsApp | Same as KML |

**What you get in the KML/KMZ:**
- One folder per observation code (Bedding Plane, Spring, etc.).
- Coloured placemark icons per code.
- A click-balloon on each point showing all 11 parameters.
- **Geological T-symbols** drawn at true ground orientation for every plane observation: an orange ~16 m strike bar plus a blue ~6 m dip-direction stem. This replaces the manual T-drawing step you used to do in Google Earth.
- Full schema'd extended data so QGIS / Earth Engine can query individual fields.

After tapping a format the Android share sheet opens — pick **WhatsApp**, **Drive**, **Gmail**, or **Save to Files**. The file is saved at:
```
/data/data/org.chirag.springshed/files/exports/<spring-name>_survey.<csv|kml|kmz>
```
…and the share sheet sends a copy.

---

## 9. Field Workflow — Step by Step

A complete spring-shed survey, start to finish:

1. **Home screen** → tap **+ New Spring**.
2. **New project form** → fill spring name + your name → **Create project**.
3. At the **spring discharge point**: walk to it → **+ Add Entry** → wait for GPS to lock (green chip) → set observation code to **Spring** → pick a spring sub-type → tap **Capture** → **Save**.
4. At each **bedding plane / foliation outcrop** uphill of the spring:
   - Lay the phone **flat** on the rock surface with the long edge along the steepest line.
   - Wait for the compass dial to stop drifting.
   - Tap **Capture** and hold still for ~2 seconds.
   - Set observation code (**Bedding Plane**, etc.), enter rock type, tap **Save**.
5. Repeat for at least **3–5 plane observations** to get a meaningful recharge-fan prediction.
6. Back on the project screen → check the **Recharge analysis** card — the up-dip direction tells you which way the recharge zone is.
7. **Open Recharge-Zone Map** to visualise.
8. **Export as KMZ** → share via WhatsApp to your supervisor / office.
9. In the office: open the KMZ in **Google Earth Pro** to inspect the geological T-symbols and recharge fan over satellite imagery.

---

## 10. Important Notes & Field Tips

### Dip-amount correction (already built in)
The app assumes you're holding the phone **edge-on** to the rock plane (clinometer-card style). The raw sensor reading in that posture is the *complement* of the true dip, so the app automatically applies **true dip = 90° − measured**. You don't have to do this in your head — the dashboard, the saved entry, the CSV, KML and KMZ all show the corrected value.

### Magnetic compass calibration
If the compass status chip says **Unreliable**, your phone's magnetometer needs recalibration:
- Move away from metal (rebar, fences, vehicles).
- Wave the phone in a **figure-8** motion in the air for 5–10 seconds.
- Wait until the chip turns green (Reliable).
- *Then* tap Capture.

### GPS accuracy under canopy
Deep forest blocks satellites. Two tactics:
- Move to a small clearing if possible — even a 3 m gap helps.
- Wait. First-fix can take 30–90 s, then re-fix is fast. The chip shows live accuracy.
- The app refuses to capture a fix worse than **10 m** by default; it tells you so via toast.

### Battery
Continuous GPS + magnetometer drains ~10–15 %/hour. Carry a power bank for long traverses. Air-plane mode (with location ON) saves a few percent.

### Backup
Until you export, all data lives on the phone. **Do not uninstall the app** without exporting first. The app's `exports/` folder is excluded from Android cloud backup by design (the DB itself is backed up).

### Keystore (for developer / handover only)
Future updates must be signed with the same keystore at `chirag_springshed/chirag-release.jks` (alias and password held by CHIRAG; not published). Losing it means surveyors must uninstall the old app before installing any update.

---

## 11. Troubleshooting

| Symptom | Fix |
|---|---|
| "Searching…" GPS for >2 min | Move to clearer sky, restart the app, check Location is set to High accuracy in Android Settings |
| Compass dial spinning wildly | Figure-8 calibration; move away from metal |
| Export tap does nothing | Check storage permission. Retry; the app shows a toast with the actual error |
| WhatsApp says "Sending file" but no file | Update WhatsApp to the latest version. Try Drive / Gmail to confirm export works |
| Strike & dip look right but dip amount looks wrong | The 90° correction is hard-coded for edge-on phone placement. If you're laying the phone face-flat instead, that's the inverse — let the developer know |
| KML doesn't show T-symbols in Google Earth | Open the KML in **Google Earth Pro desktop**, not the mobile/web version (Earth on web ignores extra LineString placemarks) |

---

## 12. Glossary

| Term | Meaning |
|---|---|
| **Strike** | The bearing of a horizontal line drawn on a tilted rock plane. Measured clockwise from true north (0–360°) |
| **Dip direction** | The compass bearing in which the plane tilts downward. Always perpendicular to strike |
| **Dip amount** | The angle the plane makes with horizontal (0° = flat, 90° = vertical) |
| **Up-dip** | Opposite of dip direction — the way water travels *into* the rock to reach the recharge zone |
| **Recharge zone** | The area uphill of the spring where rain enters the rock system. The app predicts this as a fan polygon |
| **KML** | Keyhole Markup Language — XML format for geographic data. Standard for Google Earth |
| **KMZ** | A ZIP-compressed KML. Same content, smaller, single-file |
| **Magnetic declination** | Difference between magnetic north (what the phone's compass reads) and true north. Automatically corrected for at every observation |

---

*Manual produced for CHIRAG Springshed app v1.0.0 · Summer 2026.*
