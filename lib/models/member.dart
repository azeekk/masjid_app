class Member {
  final String id, name, address, phone;
  final double monthlyAmount;
  final Map<String, dynamic> monthlyStatus; // {"2026-10": {"paid":true,"amount":500,"date":...}}

  Member({required this.id, required this.name, required this.address,
      required this.phone, required this.monthlyAmount, this.monthlyStatus = const {}});

  factory Member.fromDoc(String id, Map<String, dynamic> d) => Member(
    id: id, name: d['name'] ?? '', address: d['address'] ?? '',
    phone: d['phone'] ?? '', monthlyAmount: (d['monthlyAmount'] ?? 0).toDouble(),
    monthlyStatus: Map<String, dynamic>.from(d['monthlyStatus'] ?? {}),
  );

  Map<String, dynamic> toMap() => {
    'name': name, 'address': address, 'phone': phone,
    'monthlyAmount': monthlyAmount, 'monthlyStatus': monthlyStatus,
  };

  bool isPaidFor(String monthKey) =>
      (monthlyStatus[monthKey]?['paid'] ?? false) == true;
}