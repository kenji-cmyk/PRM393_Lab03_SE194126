import { pathToFileURL } from 'node:url';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

const PROJECT = 'vetalife-24f03';

export function parseArguments(args) {
  const values = {};
  const flags = new Set();
  for (let index = 0; index < args.length; index++) {
    const arg = args[index];
    if (['--grant', '--revoke', '--apply', '--firebase-cli'].includes(arg)) {
      if (flags.has(arg)) throw new Error('Duplicate option.');
      flags.add(arg);
    } else if (['--uid', '--email', '--project'].includes(arg)) {
      if (values[arg] !== undefined || !args[index + 1] || args[index + 1].startsWith('--')) {
        throw new Error('Missing or duplicate option value.');
      }
      values[arg] = args[++index];
    } else {
      throw new Error('Unknown option.');
    }
  }
  if (flags.has('--grant') === flags.has('--revoke') || Boolean(values['--uid']) === Boolean(values['--email'])) {
    throw new Error('Choose --grant or --revoke and exactly one --uid or --email.');
  }
  const project = values['--project'] ?? PROJECT;
  if (project !== PROJECT && !/^demo-[a-z0-9-]+$/.test(project)) {
    throw new Error('Only vetalife-24f03 or an isolated demo project is supported.');
  }
  const uid = values['--uid'];
  if (uid !== undefined && (!uid.trim() || uid !== uid.trim() || uid.length > 128 || /[\/\x00-\x1f]/.test(uid))) {
    throw new Error('Invalid user UID.');
  }
  const email = values['--email'];
  if (email !== undefined && (email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))) {
    throw new Error('Invalid email.');
  }
  return { project, uid, email, grant: flags.has('--grant'), apply: flags.has('--apply'),
    ...(flags.has('--firebase-cli') ? { firebaseCli: true } : {}) };
}

export async function manageAdmin(auth, options) {
  const user = options.uid ? await auth.getUser(options.uid) : await auth.getUserByEmail(options.email);
  if (options.grant && user.disabled) throw new Error('A disabled account cannot receive admin access.');
  const before = user.customClaims?.admin === true;
  const result = { project: options.project, uid: user.uid, wasAdmin: before, willBeAdmin: options.grant, applied: false };
  if (!options.apply || before === options.grant) return result;
  if (!options.grant && !user.disabled) {
    let pageToken;
    let hasOtherAdmin = false;
    do {
      const page = await auth.listUsers(1000, pageToken);
      hasOtherAdmin = page.users.some(candidate => candidate.uid !== user.uid &&
        !candidate.disabled && candidate.customClaims?.admin === true);
      pageToken = page.pageToken;
    } while (!hasOtherAdmin && pageToken);
    if (!hasOtherAdmin) throw new Error('Cannot revoke the last active admin.');
  }
  const claims = { ...user.customClaims };
  if (options.grant) claims.admin = true;
  else delete claims.admin;
  await auth.setCustomUserClaims(user.uid, claims);
  // Role removal is already effective in the live authorization check. Revoke
  // refresh tokens as well; do not report a failed role change if this step fails.
  if (!options.grant) {
    try {
      await auth.revokeRefreshTokens(user.uid);
    } catch {
      return { ...result, applied: true, sessionRevocationPending: true };
    }
  }
  return { ...result, applied: true };
}

async function main() {
  const options = parseArguments(process.argv.slice(2));
  const emulatorHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
  if (emulatorHost && !options.project.startsWith('demo-')) {
    throw new Error('Auth emulator requires an isolated demo project.');
  }
  if (!emulatorHost && options.project.startsWith('demo-')) {
    throw new Error('A demo project requires FIREBASE_AUTH_EMULATOR_HOST.');
  }
  const credential = options.firebaseCli
    ? await (await import('./firebase-cli-credential.mjs')).firebaseCliCredential(options.project)
    : applicationDefault();
  initializeApp({
    projectId: options.project,
    ...(emulatorHost ? {} : { credential }),
  });
  const result = await manageAdmin(getAuth(), options);
  console.log(JSON.stringify(result, null, 2));
  if (!options.apply) console.log('Dry run only. Review the UID, then add --apply to change the admin role.');
  else if (result.sessionRevocationPending) {
    console.error('Admin role removed; refresh-token revocation still needs to be retried by an operator.');
    process.exitCode = 2;
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch(error => {
    const known = [
      'Duplicate option.', 'Missing or duplicate option value.', 'Unknown option.',
      'Choose --grant or --revoke and exactly one --uid or --email.',
      'Only vetalife-24f03 or an isolated demo project is supported.',
      'Invalid user UID.', 'Invalid email.', 'A disabled account cannot receive admin access.',
      'Cannot revoke the last active admin.', 'Auth emulator requires an isolated demo project.',
      'A demo project requires FIREBASE_AUTH_EMULATOR_HOST.',
    ];
    console.error(known.includes(error.message) ? error.message :
      'Admin role operation failed. Check trusted Application Default Credentials, project IAM and the target account. Raw credentials/provider details withheld.');
    process.exitCode = 1;
  });
}
