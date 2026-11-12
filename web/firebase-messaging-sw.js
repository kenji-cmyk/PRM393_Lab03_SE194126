/* Public Firebase client identifiers, matching lib/firebase_options.dart.
 * Serve at /firebase-messaging-sw.js over HTTPS (localhost is supported).
 * FCM displays notification payloads in the background. Prefer generic titles
 * and bodies; never put health/profile details in an OS notification.
 */
// Register before Firebase so taps use our fixed same-origin destination rather
// than an arbitrary URL supplied in a message.
importScripts('notification-history.js');

const notificationItem = (payload, isRead = false) => {
  const raw = payload.data || {};
  const allowed = ['home', 'journal', 'learn', 'progress'];
  return {
    id: payload.messageId || payload.fcmMessageId || raw.messageId,
    ownerUid: raw.ownerUid,
    title: String(payload.notification?.title || raw.title || '').slice(0, 160),
    body: String(payload.notification?.body || raw.body || '').slice(0, 1000),
    receivedAt: new Date().toISOString(),
    destination: allowed.includes(raw.destination) ? raw.destination : 'home',
    isRead,
  };
};

self.addEventListener('notificationclick', (event) => {
  const payload = event.notification.data?.vetalifePayload ||
    event.notification.data?.FCM_MSG;
  if (!payload?.data?.ownerUid) return;
  event.stopImmediatePropagation();
  event.notification.close();
  const item = notificationItem(payload, true);
  if (!item.id) return;
  const url = new URL('./', self.location.href);
  // Only an opaque lookup ID enters browser history, never recipient/content.
  url.searchParams.set('vetalife_notification', item.id);
  event.waitUntil(globalThis.vetalifeNotificationHistorySave(item)
    .then(() => clients.matchAll({ type: 'window', includeUncontrolled: true }))
    .then(async (windows) => {
      const existing = windows.find((client) => new URL(client.url).origin === url.origin);
      if (existing) {
        await existing.navigate(url.href);
        return existing.focus();
      }
      return clients.openWindow(url.href);
    }));
});

importScripts('https://www.gstatic.com/firebasejs/12.3.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/12.3.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyABxNZRKO6HFOHp5AagG9HV7pKbboN1eiI',
  appId: '1:455537300059:web:74e2fcd06bfd330291257e',
  messagingSenderId: '455537300059',
  projectId: 'vetalife-24f03',
  authDomain: 'vetalife-24f03.firebaseapp.com',
  storageBucket: 'vetalife-24f03.firebasestorage.app',
});

firebase.messaging().onBackgroundMessage(async (payload) => {
  // Notification payloads are already displayed by FCM. Data-only messages
  // require an explicit display operation in the service worker.
  if (!payload.data?.ownerUid) return;
  await globalThis.vetalifeNotificationHistorySave(notificationItem(payload));
  if (payload.notification) return;
  return self.registration.showNotification(
    'VetaLife',
    {
      body: 'Bạn có thông báo mới.',
      icon: '/icons/Icon-192.png',
      data: { vetalifePayload: payload },
    },
  );
});
