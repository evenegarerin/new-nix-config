## PWA Requirement

Every website must be built as a Progressive Web App. No exceptions.

- Include a valid `manifest.json` (name, short_name, icons 192px + 512px, start_url, display: standalone, theme_color, background_color)
- Register a service worker that caches core assets and provides an offline fallback
- Development: serve over HTTP on `localhost`
- Production: serve over HTTPS
- Must be installable and pass Lighthouse PWA checks in production