// Explicit live test: at most one meal analysis plus optional synthetic OCR.
// Uses existing Firebase CLI login and revokes its temporary App Check token.
const fs = require('node:fs');
const path = require('node:path');
const {randomUUID} = require('node:crypto');
const {spawnSync} = require('node:child_process');

const root = path.resolve(__dirname, '..');
const project = 'vetalife-24f03';
const appId = '1:455537300059:web:74e2fcd06bfd330291257e';
const ocrOnly = process.argv.includes('--ocr-only');
const includeOcr = process.argv.includes('--include-ocr') || ocrOnly;
const env = {...process.env, FIREBASE_CLI_EXPERIMENTS:
  [...new Set([...(process.env.FIREBASE_CLI_EXPERIMENTS ?? '').split(','), 'appcheckadmin'])].filter(Boolean).join(',')};
let cli;

function firebase(args) {
  const result = spawnSync(process.execPath, [cli, ...args, '--project', project, '--non-interactive', '--json'],
    {cwd: root, env, encoding: 'utf8', timeout: 90000, windowsHide: true});
  if (result.status !== 0) throw new Error('Firebase CLI operation failed; check login, project access and App Check API setup. Raw CLI output withheld.');
  try {
    return JSON.parse(result.stdout.slice(result.stdout.search(/\{\s*"status"\s*:/))).result;
  } catch {
    throw new Error('Firebase CLI returned an unreadable result; raw output withheld.');
  }
}

async function main() {
  if (process.platform !== 'win32' || process.argv.slice(2).some(arg => !['--include-ocr', '--ocr-only'].includes(arg)) ||
      (ocrOnly && process.argv.includes('--include-ocr'))) {
    throw new Error('Run on Windows with Node 22+: node tool/run_meal_ai_live_check.cjs [--include-ocr | --ocr-only]');
  }
  const located = spawnSync('where.exe', ['firebase.cmd'], {encoding: 'utf8', windowsHide: true});
  const wrapper = located.stdout?.trim().split(/\r?\n/)[0];
  cli = wrapper && path.join(path.dirname(wrapper), 'node_modules/firebase-tools/lib/bin/firebase.js');
  if (located.status !== 0 || !cli || !fs.existsSync(cli)) {
    throw new Error('Install the Firebase CLI with npm and run firebase login first.');
  }
  const publicOptions = fs.readFileSync(path.join(root, 'lib/firebase_options.dart'), 'utf8');
  const apiKey = publicOptions.match(/static const FirebaseOptions web = FirebaseOptions\([\s\S]*?apiKey: '([^']+)'/)?.[1];
  if (!apiKey) throw new Error('Public Firebase web configuration could not be read.');
  const secret = randomUUID();
  const registration = firebase(['appcheck:debugtokens:create', secret, '--app', appId,
    '--display-name', `VetaLife live check ${randomUUID().slice(0, 8)}`]);
  let tokenFile;
  try {
    if (!registration?.name?.startsWith(`projects/455537300059/apps/${appId}/debugTokens/`)) {
      throw new Error('Unexpected App Check registration; inspect temporary VetaLife live-check tokens in Firebase Console.');
    }
    const exchange = await fetch(`https://firebaseappcheck.googleapis.com/v1/projects/455537300059/apps/${appId}:exchangeDebugToken`, {
      method: 'POST', headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
      body: JSON.stringify({debugToken: secret}), signal: AbortSignal.timeout(30000),
    });
    const attestation = await exchange.json();
    if (!exchange.ok || typeof attestation.token !== 'string') {
      throw new Error(`App Check token exchange failed (HTTP ${exchange.status}); check App Check API and project setup.`);
    }
    const tempDirectory = path.join(root, 'tmp');
    fs.mkdirSync(tempDirectory, {recursive: true});
    tokenFile = path.join(tempDirectory, `meal-ai-live-${randomUUID()}.json`);
    fs.writeFileSync(tokenFile, JSON.stringify({token: attestation.token}), {mode: 0o600, flag: 'wx'});
    console.log(`Running live AI Logic checks (${ocrOnly ? 'synthetic OCR only' : includeOcr ? 'analysis + synthetic OCR' : 'analysis only'}). No personal data or Gemini secret is used.`);
    const testCommand = 'flutter.bat test --no-pub test/live/meal_ai_spark_live_test.dart' +
      (ocrOnly ? ' --plain-name=PNG' : '');
    const run = spawnSync('cmd.exe', ['/d', '/s', '/c', testCommand], {
      cwd: root, stdio: 'inherit', windowsHide: true, timeout: 180000,
      env: {...process.env, VETALIFE_RUN_LIVE_AI: '1', VETALIFE_RUN_LIVE_OCR: includeOcr ? '1' : '0',
        VETALIFE_LIVE_APP_CHECK_FILE: tokenFile},
    });
    process.exitCode = run.status ?? 1;
  } finally {
    try {
      if (registration?.name?.startsWith(`projects/455537300059/apps/${appId}/debugTokens/`)) {
        firebase(['appcheck:debugtokens:delete', registration.name, '--app', appId, '--force']);
        console.log('Temporary App Check debug token revoked.');
      }
    } finally {
      if (tokenFile) fs.unlinkSync(tokenFile);
    }
  }
}

main().catch(error => {
  // Only messages created above are safe to print; fetch/OS errors may include context.
  const message = error instanceof Error && /^(Run on Windows|Install the Firebase|Public Firebase|Firebase CLI|Unexpected App Check|App Check token exchange)/.test(error.message)
    ? error.message : 'Live check failed; inspect local setup. Raw credential/provider data withheld.';
  console.error(message);
  process.exitCode = 1;
});
