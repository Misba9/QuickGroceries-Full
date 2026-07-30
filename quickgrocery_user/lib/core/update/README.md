# In-App Updates

Production update prompts for the **User** app (Android + iOS).

## Remote Config

Parameter key: **`user_app_update`** (JSON string)

```json
{
  "minimum_supported_version": "1.2.0",
  "latest_version": "1.4.0",
  "force_update": false,
  "update_title": "New Update Available",
  "update_message": "We've added new features and improved performance."
}
```

Firebase Console → Remote Config → add parameter → publish.

| Field | Meaning |
|-------|---------|
| `minimum_supported_version` | Installed below this → **force** update |
| `latest_version` | Store version you just shipped |
| `force_update` | `true` → no Later button |
| `update_title` / `update_message` | Dialog copy |

Vendor / Delivery use `vendor_app_update` / `delivery_app_update`.

## Publishing a new version

1. Bump `version:` in `pubspec.yaml` (e.g. `1.4.0+9`).
2. Ship to Play Store / App Store.
3. Set Remote Config `latest_version` to `1.4.0`.
4. Leave `force_update: false` for normal releases (Android **flexible**).

## Force updates

Set either:

- `"force_update": true`, or
- `"minimum_supported_version"` above what older installs have

Users see a blocking dialog (Update Now only). Android uses **immediate** Play updates when available.

## Modes

```dart
enum UpdateMode { disabled, flexible, immediate, remoteControlled }
```

`AppUpdateBootstrap` defaults to `remoteControlled`.

## Platform behavior

| | Android | iOS |
|--|---------|-----|
| Soft | Flexible IAU + restart prompt | App Store version check + Cupertino dialog |
| Hard | Immediate IAU (fallback: Play listing) | Force Cupertino dialog → App Store |

## Throttle

Optional checks: max once every **6 hours**. Force updates always prompt.

Skipped on OTP / login / payment / checkout / live tracking; retried on a safe screen.

## Local testing

```dart
final svc = AppUpdateService(mode: UpdateMode.remoteControlled);
svc.fakeInstalledVersion = '1.0.0';
svc.fakeConfig = const AppUpdateConfig(
  minimumSupportedVersion: '1.2.0',
  latestVersion: '1.1.0',
  forceUpdate: true,
  updateTitle: 'Update required',
  updateMessage: 'Test force update',
);
await svc.checkAndPrompt(context, ignoreThrottle: true);
```

Play In-App Updates require an install from Play (internal testing track).

## Architecture

`lib/core/update/` — `update_service`, `version_checker`, `update_dialog`,
`play_store_updater`, `app_store_updater`, `remote_config_service`,
`version_compare`, plus preferences / bootstrap / store links.
