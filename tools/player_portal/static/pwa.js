/* Shared PWA + notification helpers for the Legendary portal.
   Include with <script src="/pwa.js"></script>. Exposes window.Legendary. */
(function () {
  // ---- service worker + install ------------------------------------------
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => navigator.serviceWorker.register('/sw.js').catch(() => {}));
  }
  let deferredPrompt = null;
  window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault(); deferredPrompt = e;
    document.querySelectorAll('[data-install]').forEach((b) => { b.style.display = ''; });
  });

  function urlB64ToUint8(base64) {
    const pad = '='.repeat((4 - (base64.length % 4)) % 4);
    const b64 = (base64 + pad).replace(/-/g, '+').replace(/_/g, '/');
    const raw = atob(b64); return Uint8Array.from([...raw].map((c) => c.charCodeAt(0)));
  }

  // ---- in-app toast -------------------------------------------------------
  function toast(msg, kind) {
    let host = document.getElementById('lg-toasts');
    if (!host) {
      host = document.createElement('div'); host.id = 'lg-toasts';
      host.style.cssText = 'position:fixed;z-index:9999;left:50%;bottom:22px;transform:translateX(-50%);' +
        'display:flex;flex-direction:column;gap:8px;align-items:center;pointer-events:none';
      document.body.appendChild(host);
    }
    const t = document.createElement('div');
    t.textContent = msg;
    t.style.cssText = 'pointer-events:auto;max-width:90vw;padding:11px 16px;border-radius:10px;font-size:13.5px;' +
      'color:#e6edf3;background:#1a1f28;border:1px solid ' + (kind === 'win' ? '#d8ab33' : '#2b323d') +
      ';box-shadow:0 8px 30px rgba(0,0,0,.5);opacity:0;transition:opacity .25s,transform .25s;transform:translateY(8px)';
    host.appendChild(t);
    requestAnimationFrame(() => { t.style.opacity = '1'; t.style.transform = 'translateY(0)'; });
    setTimeout(() => { t.style.opacity = '0'; setTimeout(() => t.remove(), 300); }, kind === 'win' ? 6000 : 3800);
  }

  // ---- celebratory confetti burst (achievement moments) ------------------
  function celebrate() {
    const cv = document.createElement('canvas');
    cv.style.cssText = 'position:fixed;inset:0;z-index:9998;pointer-events:none';
    document.body.appendChild(cv);
    const ctx = cv.getContext('2d'); const W = cv.width = innerWidth, H = cv.height = innerHeight;
    const cols = ['#ecc25f', '#d8ab33', '#e6edf3', '#8fe0b0', '#f3d680'];
    const bits = Array.from({ length: 140 }, () => ({
      x: W / 2 + (Math.random() - 0.5) * 120, y: H / 3,
      vx: (Math.random() - 0.5) * 14, vy: Math.random() * -13 - 4,
      c: cols[(Math.random() * cols.length) | 0], s: 4 + Math.random() * 6, r: Math.random() * 6
    }));
    let frame = 0;
    (function tick() {
      ctx.clearRect(0, 0, W, H); frame++;
      bits.forEach((b) => {
        b.vy += 0.32; b.x += b.vx; b.y += b.vy; b.r += 0.2;
        ctx.save(); ctx.translate(b.x, b.y); ctx.rotate(b.r);
        ctx.fillStyle = b.c; ctx.fillRect(-b.s / 2, -b.s / 2, b.s, b.s * 1.6); ctx.restore();
      });
      if (frame < 150) requestAnimationFrame(tick); else cv.remove();
    })();
  }

  // ---- Web Push opt-in ----------------------------------------------------
  async function enablePush() {
    try {
      if (!('serviceWorker' in navigator) || !('PushManager' in window)) {
        toast('This browser can’t do push notifications.'); return false;
      }
      const perm = await Notification.requestPermission();
      if (perm !== 'granted') { toast('Notifications not enabled.'); return false; }
      const cfg = await fetch('/api/push/vapid').then((r) => r.json());
      if (!cfg.enabled || !cfg.key) { toast('Push isn’t set up on the server yet.'); return false; }
      const reg = await navigator.serviceWorker.ready;
      const sub = await reg.pushManager.subscribe({
        userVisibleOnly: true, applicationServerKey: urlB64ToUint8(cfg.key)
      });
      const j = sub.toJSON();
      const res = await fetch('/api/push/subscribe', {
        method: 'POST', credentials: 'include', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ endpoint: j.endpoint, p256dh: j.keys.p256dh, auth: j.keys.auth })
      });
      if (res.ok) { toast('Notifications on — we’ll ping you on big moments.', 'win'); return true; }
      toast('Could not save subscription.'); return false;
    } catch (e) { toast('Notification setup failed.'); return false; }
  }

  async function install() {
    if (!deferredPrompt) { toast('Use your browser menu → “Install app”.'); return; }
    deferredPrompt.prompt(); await deferredPrompt.userChoice; deferredPrompt = null;
  }

  window.Legendary = { toast, celebrate, enablePush, install };
})();
