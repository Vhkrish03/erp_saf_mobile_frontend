import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  try {
    var r1 = await http.get(
      Uri.parse('https://erp-saf-backend.onrender.com/api/admin/students'),
    );
    if (r1.statusCode != 200) {
      print('Failed list: ${r1.statusCode}');
      return;
    }

    var list = jsonDecode(r1.body) as List;
    if (list.isEmpty) {
      print('No students');
      return;
    }

    var s = list.first;
    var id = s['id'];
    print('Testing password for id: $id');

    var r2 = await http.get(
      Uri.parse(
        'https://erp-saf-backend.onrender.com/api/admin/students/${Uri.encodeComponent(id.toString())}/password',
      ),
    );
    print('Status: ${r2.statusCode}');
    print('Body: ${r2.body}');
  } catch (e) {
    print(e);
  }
}
