import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<Map<String, String>> users = [];
  List<Map<String, String>> hostels = [];
  final _formKey = GlobalKey<FormState>();
  TextEditingController blockNameController = TextEditingController();
  TextEditingController roomTypeController = TextEditingController();
  TextEditingController priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadHostels();
  }

  Future<void> _loadUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? userStrings = prefs.getStringList('users') ?? [];
    setState(() {
      users = userStrings.map((user) {
        var details = user.split(',');
        return {'username': details[0], 'email': details[1], 'password': details[2]};
      }).toList();
    });
  }

  Future<void> _loadHostels() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? hostelStrings = prefs.getStringList('hostels') ?? [];
    List<String>? bookingRequests = prefs.getStringList('bookingRequests') ?? [];

    setState(() {
      hostels = hostelStrings.map((hostel) {
        var details = hostel.split(',');
        var occupiedBy = bookingRequests.firstWhere(
          (request) => request.contains(details[0]),
          orElse: () => '',
        );
        var userEmail = occupiedBy.isNotEmpty ? occupiedBy.split(',')[0] : '';
        var status = details.length > 3 ? details[3] : 'available';
        return {
          'blockName': details[0],
          'roomType': details[1],
          'price': details[2],
          'status': status,
          'occupiedBy': userEmail,
        };
      }).toList();
    });
  }

  Future<void> _deleteHostel(String blockName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? hostelStrings = prefs.getStringList('hostels') ?? [];
    hostelStrings.removeWhere((hostel) => hostel.startsWith(blockName));
    await prefs.setStringList('hostels', hostelStrings);
    _loadHostels();  // Reload the hostel list after deletion
  }

  Future<void> _deleteUser(String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? userStrings = prefs.getStringList('users') ?? [];
    userStrings.removeWhere((user) => user.contains(email));
    await prefs.setStringList('users', userStrings);
    _loadUsers();  // Reload the user list after deletion
  }

  Future<void> _acceptBooking(Map<String, String> booking) async {
    var blockName = booking['blockName']!;
    var userEmail = booking['email']!;
    
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Update hostel status
    List<String>? hostelStrings = prefs.getStringList('hostels') ?? [];
    hostelStrings = hostelStrings.map((hostel) {
      var hostelDetails = hostel.split(',');
      if (hostelDetails[0] == blockName) {
        hostelDetails[3] = 'occupied'; // Update status
        return hostelDetails.join(',');
      }
      return hostel;
    }).toList();
    await prefs.setStringList('hostels', hostelStrings);

    // Remove booking request
    List<String>? bookingStrings = prefs.getStringList('bookingRequests') ?? [];
    bookingStrings.removeWhere((request) => request.contains(blockName));
    await prefs.setStringList('bookingRequests', bookingStrings);

    // Store notification message for user
    List<String>? userNotifications = prefs.getStringList('notifications_$userEmail') ?? [];
    userNotifications.add('Your booking request for $blockName has been accepted. The room is now occupied.');
    await prefs.setStringList('notifications_$userEmail', userNotifications);

    // Notify admin
    setState(() {});
  }

  Future<void> _rejectBooking(Map<String, String> booking) async {
    var blockName = booking['blockName']!;
    
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Remove booking request
    List<String>? bookingStrings = prefs.getStringList('bookingRequests') ?? [];
    bookingStrings.removeWhere((request) => request.contains(blockName));
    await prefs.setStringList('bookingRequests', bookingStrings);

    // Notify admin
    setState(() {});
  }

  Future<void> _addHostel() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? hostelStrings = prefs.getStringList('hostels') ?? [];
    hostelStrings.add('${blockNameController.text},${roomTypeController.text},${priceController.text},available');
    await prefs.setStringList('hostels', hostelStrings);
    blockNameController.clear();
    roomTypeController.clear();
    priceController.clear();
    _loadHostels(); // Refresh the list
  }

  void _showAddHostelDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Hostel'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: blockNameController,
                  decoration: const InputDecoration(labelText: 'Block Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter block name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: roomTypeController,
                  decoration: const InputDecoration(labelText: 'Room Type'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter room type';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter price';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await _addHostel();
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Page'),
          actions: [
            IconButton(
              icon: Icon(Icons.notifications),
              onPressed: () {
                // Add functionality to view notifications
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: 'Users'),
              Tab(text: 'Hostels'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Users Tab
            ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  title: Text(user['username']!),
                  subtitle: Text(user['email']!),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      _deleteUser(user['email']!);
                    },
                  ),
                );
              },
            ),
            // Hostels Tab
            ListView.builder(
              itemCount: hostels.length,
              itemBuilder: (context, index) {
                final hostel = hostels[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(hostel['blockName']!),
                    subtitle: Text('${hostel['roomType']} - \$${hostel['price']} (${hostel['status']})\nOccupied By: ${hostel['occupiedBy']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hostel['status'] == 'available') 
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _deleteHostel(hostel['blockName']!);
                            },
                          ),
                        ElevatedButton(
                          onPressed: () {
                            // Open a dialog to accept or reject booking
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Manage Booking'),
                                  content: Text('Manage booking for ${hostel['blockName']}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _acceptBooking({
                                          'blockName': hostel['blockName']!,
                                          'email': 'someuser@example.com' // Get the email from booking request
                                        });
                                      },
                                      child: Text('Accept'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _rejectBooking({
                                          'blockName': hostel['blockName']!,
                                          'email': 'someuser@example.com' // Get the email from booking request
                                        });
                                      },
                                      child: Text('Reject'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Text('Manage'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddHostelDialog,
          child: Icon(Icons.add),
          tooltip: 'Add Hostel',
        ),
      ),
    );
  }
}
