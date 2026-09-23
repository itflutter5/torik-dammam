# Android push notifications

Android installations that allow notifications subscribe to the public
`marketplace_new_posts` Firebase Cloud Messaging topic. Login is not required.
New free posts notify immediately after publication; paid posts notify only after
administrator approval. Pending and rejected posts are not broadcast.

The Android app displays notifications in the foreground and background. Tapping
a notification opens the marketplace. Users can disable the “New marketplace
posts” channel or notifications entirely in Android settings. Existing app
installations must update to a build containing this integration.

## Activate Firebase

1. Create a project in the [Firebase console](https://console.firebase.google.com/).
2. Add an Android app with the exact application ID
   `com.torikdammam.marketplace`.
3. Download its `google-services.json` and place it at
   `client/android/app/google-services.json`. This file is ignored by Git.
4. For GitHub Actions builds, create the repository **variable**
   `FIREBASE_GOOGLE_SERVICES_JSON` containing that file's complete JSON. The
   workflow writes the configuration before building Android.
5. In Firebase Project settings → Service accounts, generate a service-account
   private key. Set the complete JSON as the **secret server environment variable**
   `FIREBASE_SERVICE_ACCOUNT_JSON` in Render. Do not put this private key in the
   Android app, GitHub repository variables, or source control.
6. Ensure the Firebase Cloud Messaging API (HTTP v1) is enabled for the same
   project and the service account has permission to send FCM messages.
7. Deploy the server (its startup migration creates the notification queue),
   rebuild the Android app, install it, open it, and grant notification permission.

Android builds require `google-services.json`, supplied locally or by the GitHub
Actions repository variable. The server still runs without its Firebase service
account, but push delivery is disabled. Configuring only one side does not enable
delivery.

## Delivery and checks

- The database queues posts transactionally on publication. Each post has one
  queue entry, so editing or reapproving it does not create another broadcast.
- The server checks the queue every 10 seconds. Temporary delivery failures retry
  with exponential backoff. Entries older than 24 hours and expired or nonpublic
  posts are not sent. Posts already present before this migration are not backfilled.
- A crash between FCM acceptance and recording success can cause a retry. Android
  notification tags reuse the post ID to replace duplicate tray entries.
- On a Google Play services Android device, test a new free post with the app in
  the foreground, background, and normally closed. Then test a paid post: no alert
  while pending, one after approval. Verify rejection and repeat approval do not
  produce new queue entries. Check notification denial and disabled channels.
- Force-stopped apps must be opened again before receiving notifications.
- Automated checks: `flutter test` in `client`, and
  `node --test --test-isolation=none test/push_notifications.test.js` in `server`
  (Node 24). Database migrations and live device delivery need a configured test
  database and Firebase project.

References: [Flutter FCM setup](https://firebase.google.com/docs/cloud-messaging/flutter/get-started),
[message handling](https://firebase.google.com/docs/cloud-messaging/flutter/receive),
[FCM HTTP v1 setup](https://firebase.google.com/docs/cloud-messaging/send/v1-api).
