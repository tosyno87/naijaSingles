import 'dart:convert';
import 'dart:io';

import 'package:naijasingles/services/match_experiment_guardrail_evaluator.dart';
import 'package:naijasingles/services/match_experiment_report_builder.dart';

Future<void> main(List<String> args) async {
  final inputPath = _readArg(args, '--input');
  final outputPath = _readArg(args, '--output');
  final failOn = _readArg(args, '--fail-on');

  if (inputPath == null || inputPath.isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/match_experiment_report.dart '
      '--input <path> [--output <path>] [--fail-on promote|hold|rollback]',
    );
    exitCode = 64;
    return;
  }

  try {
    final rawText = await File(inputPath).readAsString();
    final decoded = jsonDecode(rawText);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Input JSON must be an object.');
    }

    final input = MatchExperimentReportInput.fromMap(decoded);
    final report = const MatchExperimentReportBuilder().build(input);
    final output = const JsonEncoder.withIndent('  ').convert(report.toMap());

    if (outputPath != null && outputPath.isNotEmpty) {
      await File(outputPath).writeAsString('$output\n');
    } else {
      stdout.writeln(output);
    }

    if (failOn != null && failOn.isNotEmpty) {
      final matching = MatchExperimentDecision.values
          .where((d) => d.name == failOn)
          .toList(growable: false);
      if (matching.isEmpty) {
        stderr.writeln(
          'Unknown --fail-on value "$failOn". Expected: '
          '${MatchExperimentDecision.values.map((d) => d.name).join(', ')}',
        );
        exitCode = 64;
        return;
      }
      if (report.evaluation.decision == matching.single) {
        exitCode = 1;
      }
    }
  } on FormatException catch (e) {
    stderr.writeln('Invalid report input: ${e.message}');
    exitCode = 65;
  } on FileSystemException catch (e) {
    stderr.writeln('I/O error: $e');
    exitCode = 66;
  } on Object catch (e) {
    stderr.writeln('Unexpected error while building report: $e');
    exitCode = 1;
  }
}

String? _readArg(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index < 0 || index + 1 >= args.length) {
    return null;
  }
  return args[index + 1];
}
