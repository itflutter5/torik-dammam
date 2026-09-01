# ScrapMarket

Flutter marketplace for daily work and buying or selling scrap. The same client
targets Android and the web.

## Current MVP

- Phone number and OTP sign-in flow UI
- Work, wanted, and for-sale listing filters
- Responsive phone/web marketplace grid
- Search, saved posts, my posts, and profile navigation
- Create-post form with work/buy/sell types

## Run

```powershell
cd client
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\flutter.bat run -d chrome
```

For Android, install Android Studio and its SDK, connect a device or start an
emulator, then run `C:\flutter\bin\flutter.bat run`.

## Planned services

- Node.js API on Render
- Neon PostgreSQL
- Brevo SMS OTP
- ImageKit post images
- GitHub source and Render deployment

Provider credentials must be stored as Render environment variables, never in
the Flutter app or committed files.

## Neon and ImageKit setup

The `torik-dammam` Render service provides registration, password login,
authenticated post creation, and ImageKit image uploads. Neon stores users,
posts, and the resulting ImageKit URLs. The API runs its idempotent schema
migration during startup. The Flutter app and API share one origin; API routes
are available below `https://torik-dammam.onrender.com/api`.

Set these environment variables on the API service in Render:

- `DATABASE_URL`: Neon pooled connection string with `sslmode=require`
- `IMAGEKIT_PRIVATE_KEY`: ImageKit private API key
- `IMAGEKIT_URL_ENDPOINT`: for example `https://ik.imagekit.io/account_id`
- `ALLOWED_ORIGINS`: `https://torik-dammam.onrender.com`

Render generates `JWT_SECRET` from `render.yaml`. Never expose the Neon
connection string or ImageKit private key to Flutter. For local API development,
copy `server/.env.example` to `server/.env`, fill it in, and run:

```powershell
cd server
npm install
npm start
```

The Flutter development build uses `http://localhost:10000/api`. Override it with
`--dart-define=API_BASE_URL=https://your-api.example.com` when needed.

## GitHub and Render deployment

This repository includes GitHub Actions checks and a Render Blueprint. Every
push to `main` is analyzed, tested, and compiled by GitHub Actions. When the
GitHub repository is connected to Render, Render builds the Docker image and
automatically deploys the Flutter web app.

1. Create an empty GitHub repository and push this project to its `main` branch.
2. In Render, choose **New > Blueprint** and connect that GitHub repository.
3. Select the root `render.yaml` file and create the `scrapmarket-web` service.

Render's local filesystem is ephemeral. User-uploaded listing photos must be
sent to persistent object/image storage (the planned ImageKit integration), not
written into this repository or the running Render container. GitHub is used
for application source and deployment; it is not suitable for runtime uploads.
