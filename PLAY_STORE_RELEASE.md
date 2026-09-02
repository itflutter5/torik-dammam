# Torik Dammam Android release

The GitHub workflow produces two artifacts:

- `torik-dammam-android`: APK for direct installation.
- `torik-dammam-play-store`: AAB for Google Play Console.

The permanent Android application ID is `com.torikdammam.marketplace`.

Use `client/store-assets/play-store-icon.png` for the Google Play listing
app icon. It is an opaque 512 by 512 PNG prepared for Play Console.

## Configure Play upload signing

Create and securely back up one upload keystore. Never commit it to Git. Add
these GitHub repository secrets under **Settings → Secrets and variables →
Actions**:

- `ANDROID_KEYSTORE_BASE64`: Base64 content of the upload JKS file.
- `ANDROID_STORE_PASSWORD`: Keystore password.
- `ANDROID_KEY_ALIAS`: Key alias.
- `ANDROID_KEY_PASSWORD`: Key password.

After all four secrets are saved, rerun **Flutter checks**. Download
`torik-dammam-play-store` from that successful run and upload its
`app-release.aab` file to Google Play Console.

Keep the original keystore and passwords in at least two secure backups.
Future Play Store updates must use the same upload key and a higher version
code in `client/pubspec.yaml`.

For Google sign-in on Android, also register
`com.torikdammam.marketplace` and the upload certificate SHA-1 in Google Cloud.
