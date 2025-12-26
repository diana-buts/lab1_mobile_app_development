import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/user_model.dart';
import '../models/transaction_model.dart';

class ApiService {
  static const _baseUrl = 'https://jsonplaceholder.typicode.com';

  Future<UserModel> fetchUser() async {
    final response = await http.get(Uri.parse('$_baseUrl/users/1'));

    final Map<String, dynamic> data =
        json.decode(response.body) as Map<String, dynamic>;

    return UserModel.fromJson(data);
  }

  Future<List<TransactionModel>> fetchTransactions() async {
    final response = await http.get(Uri.parse('$_baseUrl/posts?userId=1'));

    final List<dynamic> data = json.decode(response.body) as List<dynamic>;

    return data
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
