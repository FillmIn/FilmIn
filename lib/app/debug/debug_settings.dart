import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple debug logger. Only prints in debug/profile builds.
void dlog(Object? message, [StackTrace? stack]) {
  if (kDebugMode || kProfileMode) {
    final time = DateTime.now().toIso8601String();
    debugPrint('[🎞️ FILMIN][$time] $message');
    if (stack != null) debugPrint(stack.toString());
  }
}

/// Error logger with a visible prefix to filter easily.
void elog(Object? message, [StackTrace? stack]) {
  if (kDebugMode || kProfileMode) {
    final time = DateTime.now().toIso8601String();
    debugPrint('[🚨][ERROR][$time] $message');
    if (stack != null) debugPrint('[📚][STACK] ${stack.toString()}');
  }
}

/// Warning logger: shows non-fatal but notable issues.
void wlog(Object? message, [StackTrace? stack]) {
  if (kDebugMode || kProfileMode) {
    final time = DateTime.now().toIso8601String();
    debugPrint('[⚠️][WARN][$time] $message');
    if (stack != null) debugPrint('[📚][STACK] ${stack.toString()}');
  }
}

/// Internal compact log gate. When enabled, only allows our tagged lines.
class _CompactLogGate {
  static bool enabled = true; // only show tagged logs when true

  // Allow lines that carry our explicit tags or look like critical errors.
  static final List<RegExp> _allow = <RegExp>[
    RegExp(r"\[🎞️ FILMIN]"),
    RegExp(r"\[🚨]"),
    RegExp(r"\[⚠️]"),
    RegExp(r"\[📚]\[STACK]"),
    // Common framework error markers we should not hide accidentally
    RegExp(
      r"(?:Unhandled exception|Exception|Error|ASSERTION FAILED)",
      caseSensitive: false,
    ),
  ];

  static bool allow(String? line) {
    if (!enabled) return true;
    if (line == null) return false;
    for (final r in _allow) {
      if (r.hasMatch(line)) return true;
    }
    return false;
  }
}

/// Enable or disable compact console logging.
void setCompactLogging(bool enabled) {
  _CompactLogGate.enabled = enabled;
}

/// Riverpod observer to log provider updates and errors.
class AppProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    dlog(
      'Provider updated: ${provider.name ?? provider.runtimeType} -> $newValue',
    );
    super.didUpdateProvider(provider, previousValue, newValue, container);
  }

  @override
  void providerDidFail(
    ProviderBase provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    elog(
      'Provider error: ${provider.name ?? provider.runtimeType} $error',
      stackTrace,
    );
    super.providerDidFail(provider, error, stackTrace, container);
  }
}

/// Navigator observer to trace navigation.
class LoggingNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    dlog(
      'Nav push: ${route.settings.name ?? route.settings} <- ${previousRoute?.settings.name ?? previousRoute?.settings}',
    );
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    dlog(
      'Nav pop: ${route.settings.name ?? route.settings} -> ${previousRoute?.settings.name ?? previousRoute?.settings}',
    );
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    dlog('Nav remove: ${route.settings.name ?? route.settings}');
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    dlog(
      'Nav replace: ${oldRoute?.settings.name} -> ${newRoute?.settings.name}',
    );
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

/// Install global error handlers and debug hooks.
void initDebugHooks() {
  // Compact print/debugPrint filter to reduce noisy console output in debug/profile.
  if (kDebugMode || kProfileMode) {
    final originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (_CompactLogGate.allow(message)) {
        originalDebugPrint(message, wrapWidth: wrapWidth);
      }
    };
  }

  // Capture Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    final msg = details.exceptionAsString();
    if (msg.contains('Zone mismatch')) {
      wlog('FlutterWarning: $msg', details.stack);
    } else {
      elog('FlutterError: $msg', details.stack);
    }
  };

  // Capture uncaught async errors
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    final msg = error.toString();
    if (msg.contains('Zone mismatch')) {
      wlog('Uncaught warning: $msg', stack);
    } else {
      elog('Uncaught zone error: $msg', stack);
    }
    return true; // handled
  };

  // Pretty error widget in debug to spot where it happens
  ErrorWidget.builder = (FlutterErrorDetails details) {
    final msg = details.exceptionAsString();
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: const Color(0xFFB00020),
        padding: const EdgeInsets.all(12),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Widget Error',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(msg, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  };
}

/// Helper to run the app within a guarded zone and attach hooks.
Future<void> runWithDebugGuard(FutureOr<void> Function() body) async {
  initDebugHooks();
  await runZonedGuarded(
    body,
    (error, stack) {
      elog('Zone guarded error: $error', stack);
    },
    zoneSpecification: ZoneSpecification(
      // Intercept bare print() calls and filter them as well
      print: (self, parent, zone, line) {
        if (_CompactLogGate.allow(line)) {
          parent.print(zone, line);
        }
      },
    ),
  );
}
