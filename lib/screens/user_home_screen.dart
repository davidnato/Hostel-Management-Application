import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key, required this.email});

  final String email;

  @override
  _UserHomePageState createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  String username = '';
  List<Map<String, dynamic>> hostels = [];

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadHostels();
  }

  Future<void> _loadUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? users = prefs.getStringList('users');
    if (users != null) {
      for (var user in users) {
        var details = user.split(',');
        if (details[1] == widget.email) {
          setState(() {
            username = details[0];
          });
          break;
        }
      }
    }
  }

  Future<void> _loadHostels() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? hostelStrings = prefs.getStringList('hostels') ?? [];
    setState(() {
      hostels = hostelStrings.map((hostel) {
        var details = hostel.split(',');
        return {
          'blockName': details[0],
          'roomType': details[1],
          'price': details[2],
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(username.isNotEmpty ? username : 'User'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: hostels.length,
              itemBuilder: (context, index) {
                final hostel = hostels[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(hostel['blockName']!),
                    subtitle: Text('${hostel['roomType']} - \$${hostel['price']}'),
                  ),
                );
              },
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                await _deleteCredentials();
                Navigator.pop(context);  // Go back to login screen after deleting credentials
              },
              child: const Text("Log Out"),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? userStrings = prefs.getStringList('users');
    if (userStrings != null) {
      userStrings.removeWhere((user) => user.contains(widget.email));
      await prefs.setStringList('users', userStrings);
    }
    await prefs.remove('email');
    await prefs.remove('password');
  }
}
