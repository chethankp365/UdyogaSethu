# Asset Registry & Replacement Guide

This directory contains the original reference assets for UdyogaSethu.
All application assets are located in `assets/images/` and configured in `pubspec.yaml`.

> [!NOTE]
> All SVG vector assets and PNG images listed below can be replaced at any time simply by dropping a new file with the exact same filename into `assets/images/`.

---

## Asset Inventory

| Filename | Type | Primary Location & Usage | Description |
| :--- | :--- | :--- | :--- |
| `logo.png` | PNG | `assets/images/logo.png`, Splash, Intro, Auth | Primary 3D UdyogaSethu brand logo with blue bridge map pin. |
| `logo_small.png` | PNG | `assets/images/logo_small.png`, App Bars, Shell Header | Compact version of UdyogaSethu brand logo for headers and app bars. |
| `splash_city_bridge.svg` | SVG | `assets/images/splash_city_bridge.svg`, Splash Screen | Bridge connecting city skyline and rural farm hills. |
| `intro_hero.svg` | SVG | `assets/images/intro_hero.svg`, Onboarding Hero | Friendly illustration of Indian construction worker, farmer, and delivery worker. |
| `feature_find_jobs.svg` | SVG | `assets/images/feature_find_jobs.svg`, Intro Tile 1 | Location map pin with search trail. |
| `feature_secure_payments.svg` | SVG | `assets/images/feature_secure_payments.svg`, Intro Tile 2 | Green security shield with Indian Rupee (₹) symbol & verification checkmark. |
| `feature_ai_voice.svg` | SVG | `assets/images/feature_ai_voice.svg`, Intro Tile 3 | Microphone with voice soundwaves & AI sparkles. |
| `role_worker.svg` | SVG | `assets/images/role_worker.svg`, Role Selector Card | Hard-hat worker illustration card. |
| `role_farmer.svg` | SVG | `assets/images/role_farmer.svg`, Role Selector Card | Farmer with green turban & paddy crop card. |
| `role_provider.svg` | SVG | `assets/images/role_provider.svg`, Role Selector Card | Employer / Job provider illustration card. |
| `empty_jobs.svg` | SVG | `assets/images/empty_jobs.svg`, Search & Jobs Empty State | Clipboard with magnifying glass & sprout. |
| `empty_notifications.svg` | SVG | `assets/images/empty_notifications.svg`, Notification Empty State | Notification bell icon with sleeping sparkles. |

---

## How to Replace an Asset

1. Prepare your replacement image in SVG or PNG format matching the exact target filename (e.g. `logo.png` or `splash_city_bridge.svg`).
2. Overwrite the corresponding file in `assets/images/<filename>`.
3. In Flutter, hot-restart or run `flutter pub get` / rebuild to refresh the asset bundle cache.
