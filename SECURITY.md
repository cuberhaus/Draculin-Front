# Security Policy — Draculin-Front

## Reporting a Vulnerability
If you discover a security vulnerability, please email polcg10@gmail.com. Do not open a public issue.

## Security Considerations

### Health Data Handling
- This app captures and transmits images of sanitary products for health analysis. This is **sensitive personal health data**.
- Minimize the time images are stored on-device. Delete local copies after successful upload.
- Display clear privacy notices to users about what data is collected and how it's used.
- Do not send health data to analytics or crash reporting services.

### Secure API Communication
- All communication with the Draculin-Backend must use HTTPS. Never transmit health data or images over plain HTTP.
- Validate TLS certificates — do not disable certificate verification, even in development builds shipped to users.
- Use certificate pinning if targeting a known backend server to prevent MITM attacks.

### Image Data at Rest
- Uploaded images may remain in the device's cache or temp directories. Clear these after processing.
- If images are stored locally (gallery, app storage), encrypt them using platform-provided encryption APIs.
- On Android, use `EncryptedSharedPreferences` or the Keystore system. On iOS, use the Keychain.

### Local Storage Security
- Do not store API tokens, session tokens, or user credentials in plain-text shared preferences.
- Use Flutter's `flutter_secure_storage` package for sensitive data.
- Clear stored credentials on logout.

### Build & Distribution
- Do not include API keys or backend URLs in client-side code — use build-time environment configuration.
- Ensure `--release` builds have debugging and logging stripped.
- Use code obfuscation (`--obfuscate` with `--split-debug-info`) for release builds.

### Recommendations
- Implement biometric or PIN-based app lock for accessing health data.
- Add a data export/delete feature for user data ownership.
- Keep Flutter and all dependencies updated to patch known vulnerabilities.
