/* Legendary FFXI Player Portal — service worker.
   App-shell caching for instant loads + offline fallback, and Web Push. */
const CACHE = 'legendary-portal-v3';  // bump to bust the app-shell cache (network-first HTML fix)
const SHELL = [
  '/', '/index.html', '/community.html', '/market.html', '/events.html',
  '/gear-builder.html', '/augments.html', '/wrapped.html', '/achievements.html',
  '/status.html', '/next.html', '/pwa.js', '/offline.html',
  '/icons/icon-192.png', '/icons/icon-512.png', '/icons/icon.svg', '/manifest.webmanifest'
];

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(SHELL)).catch(() => {}));
  self.skipWaiting();
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
  );
  self.clients.claim();
});

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== location.origin) return;              // don't touch cross-origin (BG-Wiki imgs etc.)

  // API + auth-sensitive: always go to network, never cache (data must be fresh & per-user).
  if (url.pathname.startsWith('/api/')) {
    e.respondWith(fetch(req).catch(() => new Response('{"offline":true}',
      { headers: { 'Content-Type': 'application/json' }, status: 503 })));
    return;
  }

  const cachePut = (res) => {
    if (res && res.ok && res.type === 'basic') {
      const copy = res.clone();
      caches.open(CACHE).then((c) => c.put(req, copy)).catch(() => {});
    }
    return res;
  };

  // HTML / navigations: NETWORK-FIRST so page updates always show (this was the
  // stale-index.html bug -- cache-first served old HTML forever). Cache is only
  // the offline fallback.
  const isHTML = req.mode === 'navigate' || url.pathname === '/' || url.pathname.endsWith('.html');
  if (isHTML) {
    e.respondWith(
      fetch(req).then(cachePut).catch(() =>
        caches.match(req).then((hit) => hit || caches.match('/offline.html')))
    );
    return;
  }

  // Other static assets (js / icons / manifest): cache-first, busted by the
  // CACHE version bump above.
  e.respondWith(
    caches.match(req).then((hit) => hit || fetch(req).then(cachePut).catch(() => undefined))
  );
});

// ---- Web Push ---------------------------------------------------------------
self.addEventListener('push', (e) => {
  let data = { title: 'Legendary FFXI', body: 'Something happened in Vana’diel.', url: '/' };
  try { if (e.data) data = Object.assign(data, e.data.json()); } catch (_) {}
  e.waitUntil(self.registration.showNotification(data.title, {
    body: data.body,
    icon: '/icons/icon-192.png',
    badge: '/icons/icon-192.png',
    data: { url: data.url || '/' },
    vibrate: [80, 40, 80]
  }));
});

self.addEventListener('notificationclick', (e) => {
  e.notification.close();
  const url = (e.notification.data && e.notification.data.url) || '/';
  e.waitUntil(clients.matchAll({ type: 'window', includeUncontrolled: true }).then((list) => {
    for (const c of list) { if ('focus' in c) { c.navigate(url); return c.focus(); } }
    return clients.openWindow(url);
  }));
});
