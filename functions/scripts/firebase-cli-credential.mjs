import { spawnSync } from 'node:child_process';
import { createRequire } from 'node:module';
import path from 'node:path';

/** Local operator tooling only. Tokens remain in memory and never reach clients. */
export async function firebaseCliCredential(projectId) {
  const located = spawnSync(process.platform === 'win32' ? 'where.exe' : 'which',
    [process.platform === 'win32' ? 'firebase.cmd' : 'firebase'],
    { encoding: 'utf8', windowsHide: true, timeout: 10000 });
  if (located.status !== 0) throw new Error('Firebase CLI is not installed.');
  const wrapper = located.stdout.trim().split(/\r?\n/)[0];
  const require = createRequire(import.meta.url);
  // npm global launchers sit beside node_modules on Windows. Resolve from the
  // actual executable on Unix; no credentials or source are copied into repo.
  const fs = await import('node:fs');
  const cliLib = process.platform === 'win32'
    ? path.join(path.dirname(wrapper), 'node_modules/firebase-tools/lib')
    : path.resolve(path.dirname(fs.realpathSync(wrapper)), '..');
  const auth = require(path.join(cliLib, 'auth.js'));
  const { requireAuth } = require(path.join(cliLib, 'requireAuth.js'));
  const account = auth.getProjectDefaultAccount(process.cwd());
  if (!account) throw new Error('Run firebase login with an authorized project operator first.');
  await requireAuth({ project: projectId, nonInteractive: true, ...account });
  return {
    async getAccessToken() {
      const tokens = await auth.getAccessToken(account.tokens?.refresh_token, ['https://www.googleapis.com/auth/cloud-platform']);
      if (!tokens?.access_token) throw new Error('Firebase CLI credentials unavailable.');
      const seconds = typeof tokens.expires_at === 'number'
        ? Math.max(1, Math.floor((tokens.expires_at - Date.now()) / 1000))
        : 300;
      return { access_token: tokens.access_token, expires_in: seconds };
    },
  };
}
