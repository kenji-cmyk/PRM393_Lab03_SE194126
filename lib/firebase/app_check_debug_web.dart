import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Called only for an explicit opt-in in a debug web build, before activation.
void enableWebAppCheckDebug() {
  globalContext.setProperty('FIREBASE_APPCHECK_DEBUG_TOKEN'.toJS, true.toJS);
}
