import 'package:cloud_firestore/cloud_firestore.dart';

class Currency {
  String code;
  double rate;
  bool converted;

  Currency({
    required this.code,
    required this.rate,
    required this.converted,
  });

  factory Currency.fromDocument(DocumentSnapshot doc) {
    return Currency(
      code: doc['code'],
      rate: doc['rate'],
      converted: doc['converted'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'rate': rate,
      'converted': converted,
    };
  }

}