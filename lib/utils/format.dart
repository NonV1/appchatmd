// lib/utils/format.dart
import 'package:intl/intl.dart';

/// ---- Number & unit helpers ----
final _numNoDec = NumberFormat.decimalPattern()..maximumFractionDigits = 0;
final _num1Dec  = NumberFormat.decimalPattern()..maximumFractionDigits = 1;

String fmtInt(num? n) => n == null ? '—' : _numNoDec.format(n);
String fmt1(num? n)   => n == null ? '—' : _num1Dec.format(n);

String fmtSteps(num? steps) => steps == null ? '—' : '${fmtInt(steps)} steps';
String fmtKcal(num? kcal)   => kcal == null ? '—' : '${fmtInt(kcal)} kcal';
String fmtBpm(num? bpm)     => bpm == null ? '—' : '${fmtInt(bpm)} bpm';
String fmtSpO2(num? pct)    => pct == null ? '—' : '${fmtInt(pct)}%';

/// hh:mm (e.g., 06:32)
String fmtHm(Duration? d) {
  if (d == null) return '—';
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

/// 6h 32m (compact)
String fmtHCompact(Duration? d) {
  if (d == null) return '—';
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h > 0 && m > 0) return '${h}h ${m}m';
  if (h > 0) return '${h}h';
  return '${m}m';
}

/// Short date like “Wed, 29 Dec”
String fmtShortDate(DateTime dt) => DateFormat('EEE, d MMM').format(dt);

/// Time like “8:20 AM”
String fmtTime(DateTime dt) => DateFormat('h:mm a').format(dt);
