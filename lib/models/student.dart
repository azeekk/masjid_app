class Student {
  final String id, name, sclass;
  final double monthlyFee;
  final Map<String, dynamic> feeStatus;
  // {"2026-10": {"paid":true, "amount":500, "date":..., "method":"cash", "collectedBy":"..."}}

  Student({required this.id, required this.name, required this.sclass,
      required this.monthlyFee, this.feeStatus = const {}});

  factory Student.fromDoc(String id, Map<String, dynamic> d) => Student(
    id: id,
    name: d['name'] ?? '',
    sclass: d['class'] ?? '',
    monthlyFee: (d['monthlyFee'] ?? d['totalFee'] ?? 0).toDouble(),
    feeStatus: Map<String, dynamic>.from(d['feeStatus'] ?? {}),
  );

  bool isPaidFor(String monthKey) =>
      (feeStatus[monthKey]?['paid'] ?? false) == true;
}