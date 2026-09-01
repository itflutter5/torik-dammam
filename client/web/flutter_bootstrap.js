{{flutter_js}}
{{flutter_build_config}}

// Always load the current Render assets. Flutter's generated service worker is
// deprecated and can otherwise keep an older UI active after a deployment.
(async () => {
  if ('serviceWorker' in navigator) {
    const registrations = await navigator.serviceWorker.getRegistrations();
    await Promise.all(registrations.map((registration) => registration.unregister()));
  }
  await _flutter.loader.load();
})();
