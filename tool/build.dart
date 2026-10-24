// Release builds go through this script, so the config file always matches
// the flavor:
//
//   dart run tool/build.dart <apk|appbundle|ipa> <dev|staging|prod> [flutter build options]
//
// iOS has no Xcode schemes yet, so `appFlavor` is null there and the app
// cannot compare APP_FLAVOR with its build flavor when it starts. This script
// is that check, on every platform (re-review R-A5).
import 'dart:convert';
import 'dart:io';

const flavors = ['dev', 'staging', 'prod'];
const targets = ['apk', 'appbundle', 'ipa'];

/// Why `config/<flavor>.json` cannot ship in a [flavor] build, or null when it can.
String? configProblem(String flavor, Object? config) {
  final file = 'config/$flavor.json';
  if (config is! Map<String, dynamic>) return '$file must be a JSON object';
  if (config['APP_FLAVOR'] != flavor) return '$file has APP_FLAVOR "${config['APP_FLAVOR']}", not "$flavor"';
  final value = config['API_BASE_URL'];
  final url = value is String ? Uri.tryParse(value) : null;
  if (url == null || !url.hasScheme || !url.path.endsWith('/v1')) {
    return '$file needs an absolute API_BASE_URL ending in /v1';
  }
  if (flavor != 'dev' && url.scheme != 'https') return '$file must use HTTPS';
  return null;
}

Future<void> main(List<String> args) async {
  if (args.length < 2 || !targets.contains(args[0]) || !flavors.contains(args[1])) {
    stderr.writeln('Usage: dart run tool/build.dart <${targets.join('|')}> <${flavors.join('|')}> [options]');
    exitCode = 64;
    return;
  }
  final [target, flavor, ...options] = args;
  final file = File('config/$flavor.json');
  final problem = configProblem(flavor, jsonDecode(await file.readAsString()));
  if (problem != null) {
    stderr.writeln(problem);
    exitCode = 1;
    return;
  }
  final command = [
    'build',
    target,
    '--release',
    // iOS takes --flavor once the Xcode schemes exist (README).
    if (target != 'ipa') ...['--flavor', flavor],
    '--dart-define-from-file=${file.path}',
    ...options,
  ];
  stdout.writeln('flutter ${command.join(' ')}');
  final process = await Process.start(
    'flutter',
    command,
    mode: ProcessStartMode.inheritStdio,
    runInShell: Platform.isWindows,
  );
  exitCode = await process.exitCode;
}
