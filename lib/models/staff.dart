class Staff {
  final String id, name, role; // "teacher", "imam", "khatheeb"
  final double monthlySalary;
  final Map<String, dynamic> salaryStatus;
  // {"2026-10": {"paid":true, "amount":8000, "date":..., "method":"cash", "paidBy":"admin@...", "note":"..."}}

  Staff({required this.id, required this.name, required this.role,
      required this.monthlySalary, this.salaryStatus = const {}});

  factory Staff.fromDoc(String id, Map<String, dynamic> d) => Staff(
    id: id, name: d['name'] ?? '', role: d['role'] ?? '',
    monthlySalary: (d['monthlySalary'] ?? 0).toDouble(),
    salaryStatus: Map<String, dynamic>.from(d['salaryStatus'] ?? {}),
  );

  bool isPaidFor(String monthKey) =>
      (salaryStatus[monthKey]?['paid'] ?? false) == true;
}