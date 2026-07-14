// Cloudflare Pages Function: gate the ENTIRE relaunch site behind Basic Auth.
// This is the private relaunch docs — GM-only access.
// Deployed into functions/ (root, not admin/) by refresh_site_relaunch.sh.
export async function onRequest(context) {
  const SITE_USER = 'admin';
  const SITE_PASS = 'richard';

  const auth = context.request.headers.get('Authorization');

  if (!auth || !auth.startsWith('Basic ')) {
    return new Response('Legendary Docs — GM access only.', {
      status: 401,
      headers: {
        'WWW-Authenticate': 'Basic realm="Legendary"',
        'Content-Type': 'text/plain',
      },
    });
  }

  const decoded = atob(auth.slice(6));
  const colon = decoded.indexOf(':');
  const user = decoded.slice(0, colon);
  const pass = decoded.slice(colon + 1);

  if (user !== SITE_USER || pass !== SITE_PASS) {
    return new Response('Invalid credentials.', {
      status: 401,
      headers: {
        'WWW-Authenticate': 'Basic realm="Legendary"',
        'Content-Type': 'text/plain',
      },
    });
  }

  return context.next();
}
