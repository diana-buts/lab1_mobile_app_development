class TransactionModel {
  final int id;
  final String title;
  final double amount;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as int,
      title: json['title']?.toString() ?? '',
      amount: (json['id'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'amount': amount};
  }
}
