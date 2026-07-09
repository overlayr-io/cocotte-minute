/// Formate une durée en minutes façon "45 min" / "1 h" / "1 h 30".
/// Retourne `null` si `minutes <= 0` (masque la valeur, ex. tuile méta PDF).
String? formatMinutesShort(int minutes) {
  if (minutes <= 0) return null;
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h h' : '$h h $m';
}
