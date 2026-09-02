{{flutter_js}}
{{flutter_build_config}}

// Always load the current Render assets. Flutter's generated service worker is
// deprecated and can otherwise keep an older UI active after a deployment.
(async () => {
  const loader = document.getElementById('app-loader');
  const status = document.getElementById('startup-status');
  const setStatus = (message) => {
    if (status) status.textContent = message;
  };

  try {
    if ('serviceWorker' in navigator) {
      const registrations = await navigator.serviceWorker.getRegistrations();
      await Promise.all(registrations.map((registration) => registration.unregister()));
    }

    setStatus('Starting application…');
    await _flutter.loader.load({
      onEntrypointLoaded: async (engineInitializer) => {
        setStatus('Preparing marketplace…');
        const appRunner = await engineInitializer.initializeEngine();
        setStatus('Almost ready…');
        await appRunner.runApp();
        requestAnimationFrame(() => {
          loader?.classList.add('hide');
          setTimeout(() => loader?.remove(), 300);
        });
      },
    });
  } catch (error) {
    setStatus('Could not start. Please refresh the page.');
    throw error;
  }
})();
