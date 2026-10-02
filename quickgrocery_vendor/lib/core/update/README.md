# In-App Updates (Vendor)

Remote Config parameter: **`vendor_app_update`** (JSON string)

```json
{
  "minimum_supported_version": "1.0.0",
  "latest_version": "1.1.0",
  "force_update": false,
  "update_title": "New Update Available",
  "update_message": "We've improved vendor tools and performance."
}
```

Same architecture as the User app (`lib/core/update/`). See User app
`lib/core/update/README.md` for force updates, flexible/immediate modes,
and local testing with fake versions.
