import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';

const historySource = readFileSync(new URL('../../web/notification-history.js', import.meta.url), 'utf8');
const workerSource = readFileSync(new URL('../../web/firebase-messaging-sw.js', import.meta.url), 'utf8');

function page(url) {
  const replacements = [];
  const window = {
    location: { href: url },
    history: {
      state: { keep: 'navigation-state' },
      replaceState(state, title, nextUrl) {
        replacements.push({ state, title, url: nextUrl });
        window.location.href = nextUrl;
      },
    },
  };
  const context = vm.createContext({ URL, window });
  vm.runInContext(historySource, context);
  return { context, window, replacements };
}

function deferred() {
  let resolve;
  const promise = new Promise((done) => { resolve = done; });
  return { promise, resolve };
}

function worker({ windows = [], persist } = {}) {
  const calls = [];
  const listeners = new Map();
  let background;
  const context = vm.createContext({
    URL,
    self: {
      location: { href: 'https://vetalife.example/firebase-messaging-sw.js' },
      addEventListener(name, callback) { listeners.set(name, callback); },
      registration: {
        async showNotification(title, options) { calls.push({ type: 'display', title, options }); },
      },
    },
    importScripts(...urls) { calls.push({ type: 'import', urls }); },
    firebase: {
      initializeApp() {},
      messaging: () => ({ onBackgroundMessage(callback) { background = callback; } }),
    },
    clients: {
      async matchAll() { calls.push({ type: 'match' }); return windows; },
      async openWindow(url) { calls.push({ type: 'open', url }); },
    },
    async vetalifeNotificationHistorySave(item) {
      calls.push({ type: 'save-start', item });
      if (persist) await persist(item);
      calls.push({ type: 'save-complete', item });
    },
  });
  vm.runInContext(workerSource, context);
  return { context, calls, listeners, background: (payload) => background(payload) };
}

const payload = {
  messageId: 'opaque-message-123',
  data: {
    ownerUid: 'private-recipient',
    title: 'Private notification title',
    body: 'Private notification body',
    destination: 'learn',
  },
};

test('page removes launch ID before subsequent initialization and consumes it once', () => {
  const original = new URL('https://vetalife.example/?mode=cloud#home');
  original.searchParams.set('vetalife_notification', payload.messageId);
  const { context, window, replacements } = page(original.href);
  // Simulates the location observed by Analytics after this script has run.
  const analyticsLocation = new URL(window.location.href);
  assert.equal(analyticsLocation.searchParams.has('vetalife_notification'), false);
  assert.equal(analyticsLocation.searchParams.get('mode'), 'cloud');
  assert.equal(analyticsLocation.hash, '#home');
  assert.equal(replacements.length, 1);
  assert.equal(replacements[0].state.keep, 'navigation-state');
  assert.equal(context.vetalifeNotificationTakeLaunchId(), payload.messageId);
  assert.equal(context.vetalifeNotificationTakeLaunchId(), null);
  // The cleaned page URL cannot replay the notification after a reload.
  assert.equal(page(window.location.href).context.vetalifeNotificationTakeLaunchId(), null);
});

test('legacy content-bearing JSON launch payload is removed and rejected', () => {
  const original = new URL('https://vetalife.example/');
  original.searchParams.set('vetalife_notification', JSON.stringify(payload));
  const { context, window } = page(original.href);
  assert.equal(context.vetalifeNotificationTakeLaunchId(), null);
  assert.equal(window.location.href, 'https://vetalife.example/');
  assert.equal(window.location.href.includes(payload.data.ownerUid), false);
});

test('overlong launch values are removed without being accepted as message IDs', () => {
  const original = new URL('https://vetalife.example/');
  original.searchParams.set('vetalife_notification', 'x'.repeat(513));
  const { context, window } = page(original.href);
  assert.equal(context.vetalifeNotificationTakeLaunchId(), null);
  assert.equal(window.location.href, 'https://vetalife.example/');
});

test('worker persists background data before displaying a generic OS notification', async () => {
  const pending = deferred();
  const app = worker({ persist: () => pending.promise });
  const completion = app.background(payload);
  assert.equal(app.calls.filter((call) => call.type === 'save-start').length, 1);
  assert.equal(app.calls.some((call) => call.type === 'display'), false);
  pending.resolve();
  await completion;
  const completed = app.calls.findIndex((call) => call.type === 'save-complete');
  const displayed = app.calls.findIndex((call) => call.type === 'display');
  assert.ok(completed >= 0 && displayed > completed);
  const display = app.calls[displayed];
  assert.equal(display.title, 'VetaLife');
  assert.notEqual(display.options.body, payload.data.body);
  assert.equal(display.options.data.vetalifePayload.messageId, payload.messageId);
  const saved = app.calls[completed].item;
  assert.equal(saved.ownerUid, payload.data.ownerUid);
  assert.equal(saved.isRead, false);
});

test('worker stores notification payload once without duplicating FCM display, and ignores unscoped data', async () => {
  const app = worker();
  await app.background({ ...payload, notification: { title: 'VetaLife', body: 'New notification' } });
  assert.equal(app.calls.filter((call) => call.type === 'save-complete').length, 1);
  assert.equal(app.calls.some((call) => call.type === 'display'), false);
  await app.background({ messageId: 'unscoped', data: { title: 'Unknown owner' } });
  assert.equal(app.calls.filter((call) => call.type === 'save-start').length, 1);
});

test('notification tap persists read state then reuses same-origin client with only opaque ID in URL', async () => {
  const pending = deferred();
  const navigation = [];
  const existing = {
    url: 'https://vetalife.example/?mode=cloud',
    async navigate(url) { navigation.push(url); },
    async focus() { navigation.push('focused'); },
  };
  const wrongOrigin = {
    url: 'https://other.example/',
    async navigate() { assert.fail('A different origin must not receive navigation'); },
  };
  const app = worker({ windows: [wrongOrigin, existing], persist: () => pending.promise });
  let completion;
  let stopped = false;
  let closed = false;
  app.listeners.get('notificationclick')({
    notification: {
      data: { vetalifePayload: payload },
      close() { closed = true; },
    },
    stopImmediatePropagation() { stopped = true; },
    waitUntil(promise) { completion = promise; },
  });
  assert.equal(stopped, true);
  assert.equal(closed, true);
  assert.equal(app.calls.some((call) => call.type === 'match'), false);
  pending.resolve();
  await completion;
  assert.equal(navigation.length, 2);
  assert.equal(navigation[1], 'focused');
  const launch = new URL(navigation[0]);
  assert.equal(launch.origin, 'https://vetalife.example');
  assert.deepEqual([...launch.searchParams.entries()], [['vetalife_notification', payload.messageId]]);
  for (const value of Object.values(payload.data)) {
    assert.equal(launch.href.includes(encodeURIComponent(value)), false);
  }
  assert.equal(app.calls.some((call) => call.type === 'open'), false);
  assert.equal(app.calls.find((call) => call.type === 'save-complete').item.isRead, true);
  // The real page script can consume exactly the ID produced by the worker.
  const targetPage = page(launch.href);
  assert.equal(targetPage.context.vetalifeNotificationTakeLaunchId(), payload.messageId);
  assert.equal(targetPage.context.vetalifeNotificationTakeLaunchId(), null);
});
