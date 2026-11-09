/* Shared by the page and FCM worker. Only public notification content belongs
 * here; records remain partitioned by recipient UID and bounded to 100/UID. */
(() => {
  // Capture once and remove the launch parameter before Firebase Analytics
  // initializes. Repeated reloads must not replay a previously opened message.
  let launchId = null;
  if (typeof window !== 'undefined') {
    const url = new URL(window.location.href);
    const value = url.searchParams.get('vetalife_notification');
    if (value !== null) {
      launchId = value.length <= 512 && !value.startsWith('{') ? value : null;
      url.searchParams.delete('vetalife_notification');
      window.history.replaceState(window.history.state, '', url.href);
    }
  }
  globalThis.vetalifeNotificationTakeLaunchId = () => {
    const value = launchId;
    launchId = null;
    return value;
  };
  const database = () => new Promise((resolve, reject) => {
    const request = indexedDB.open('vetalife-notifications-v1', 1);
    request.onupgradeneeded = () => request.result.createObjectStore('inbox', { keyPath: 'key' });
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
  const keyFor = (uid, id) => `${encodeURIComponent(uid)}:${encodeURIComponent(id)}`;
  const transaction = async (mode, work) => {
    const db = await database();
    return new Promise((resolve, reject) => {
      const tx = db.transaction('inbox', mode);
      let value;
      tx.oncomplete = () => { db.close(); resolve(value); };
      tx.onerror = () => { db.close(); reject(tx.error); };
      tx.onabort = () => { db.close(); reject(tx.error); };
      work(tx.objectStore('inbox'), (result) => { value = result; });
    });
  };

  globalThis.vetalifeNotificationHistorySave = (item) => {
    if (!item.ownerUid || !item.id) return Promise.resolve();
    return transaction('readwrite', (store) => {
      const key = keyFor(item.ownerUid, item.id);
      const existing = store.get(key);
      existing.onsuccess = () => {
        // Duplicate delivery cannot revert a read notification.
        store.put({ key, item: { ...item, isRead: existing.result?.item.isRead || item.isRead } });
        const all = store.getAll();
        all.onsuccess = () => {
          all.result.filter((entry) => entry.item.ownerUid === item.ownerUid)
            .sort((a, b) => Date.parse(b.item.receivedAt) - Date.parse(a.item.receivedAt))
            .slice(100).forEach((entry) => store.delete(entry.key));
        };
      };
    });
  };
  globalThis.vetalifeNotificationHistoryLoad = (uid) => transaction('readonly', (store, done) => {
    const request = store.getAll();
    request.onsuccess = () => done(request.result
      .filter((entry) => entry.item.ownerUid === uid)
      .map((entry) => JSON.stringify(entry.item)));
  });
  globalThis.vetalifeNotificationHistoryRemove = (uid, id) => transaction('readwrite', (store) => {
    store.delete(keyFor(uid, id));
  });
})();
