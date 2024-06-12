import 'package:cloud_firestore/cloud_firestore.dart';

//currency class
class Currency {
  String code;
  double rate;


  Currency({
    required this.code,
    required this.rate,

  });

  factory Currency.fromDocument(DocumentSnapshot doc) {
    return Currency(
      code: doc['code'],
      rate: doc['rate'],

    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'rate': rate,

    };
  }

}