# Security Policy

## Local Data Storage

Activity tracks recorded by the app are stored as GPX files in app-private
storage on the device (Android: `filesDir`, iOS/macOS: the app's Application
Support directory). These files are not readable by other apps without root
access or a backup extraction, but they are **not separately encrypted at rest**
beyond any full-disk encryption the OS or device provides.

**Practical expectations:**
- A device with full-disk encryption (enabled by default on modern Android and
  iOS) protects the files while the device is locked.
- Disabling device encryption or obtaining a device backup may expose local
  track data.
- No auth tokens or credentials are stored alongside the GPX files; those are
  kept separately in the platform keychain/secure storage.

If you require stronger at-rest protection for recorded tracks, export and
delete them from the device promptly after each session.

## Reporting a Vulnerability

If you discover a security vulnerability, please follow these steps:

1. **Do not** open a public issue;
2. Send an email to joao@endurain.com with the details of the vulnerability;
3. Include the following in your report:
- Steps to reproduce the vulnerability;
- Potential impact;
- Any suggested fixes, if available.
4. I will provide an acknowledgment when possible.

Please include as much information as possible to help me resolve the issue promptly.

Thank you for helping keep this project secure!
