import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key, required this.email});

  final String email;

  @override
  _UserHomePageState createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  List<Map<String, String>> hostels = [];

  @override
  void initState() {
    super.initState();
    _loadHostels();
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
          'status': details.length > 3 ? details[3] : 'available',
        };
      }).toList();
    });
  }

  Future<void> _bookNow(String blockName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? bookingRequests = prefs.getStringList('bookingRequests') ?? [];
    
    // Add a new booking request
    bookingRequests.add('${widget.email},$blockName');
    await prefs.setStringList('bookingRequests', bookingRequests);
    
    // Notify the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking request for $blockName has been sent.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Homepage - ${widget.email}'),
      ),
      body: ListView.builder(
        itemCount: hostels.length,
        itemBuilder: (context, index) {
          final hostel = hostels[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              title: Text(hostel['blockName']!),
              subtitle: Text('${hostel['roomType']} - \$${hostel['price']}\nStatus: ${hostel['status']}'),
              trailing: hostel['status'] == 'available'
                  ? ElevatedButton(
                      onPressed: () {
                        _bookNow(hostel['blockName']!);
                      },
                      child: const Text('Book Now'),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
