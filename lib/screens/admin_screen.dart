import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  List<Map<String, String>> users = [];
  List<Map<String, String>> hostels = [];
  final _formKey = GlobalKey<FormState>();
  TextEditingController blockNameController = TextEditingController();
  TextEditingController roomTypeController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Updated tab length to 2
    _loadUsers();
    _loadHostels();
  }

  Future<void> _loadUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? userStrings = prefs.getStringList('users') ?? [];
    setState(() {
      users = userStrings.map((user) {
        var details = user.split(',');
        return {
          'username': details[0],
          'email': details[1],
          'password': details[2],
        };
      }).toList();
    });
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
          'occupants': details.length > 4 ? details[4] : '', // New field for occupants
        };
      }).toList();
    });
  }

  Future<void> _updateHostelStatus(String hostelDetails, String newStatus, [String occupant = '']) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? hostelStrings = prefs.getStringList('hostels') ?? [];
    for (int i = 0; i < hostelStrings.length; i++) {
      if (hostelStrings[i].startsWith(hostelDetails)) {
        var details = hostelStrings[i].split(',');
        hostelStrings[i] = '${details[0]},${details[1]},${details[2]},$newStatus,${occupant}';
        break;
      }
    }
    await prefs.setStringList('hostels', hostelStrings);
    _loadHostels(); // Refresh the list after updating
  }

  Future<void> _deleteHostel(String hostelDetails) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? hostelStrings = prefs.getStringList('hostels') ?? [];
    hostelStrings.removeWhere((hostel) => hostel.startsWith(hostelDetails));
    await prefs.setStringList('hostels', hostelStrings);
    _loadHostels(); // Refresh the list after deleting
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Page'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Hostels'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Users Tab
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(user['username']!),
                        subtitle: Text(user['email']!),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          // Hostels Tab
          Column(
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
                        subtitle: Text('${hostel['roomType']} - \$${hostel['price']} (Status: ${hostel['status']})'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (String value) {
                            final hostelDetails = '${hostel['blockName']},${hostel['roomType']},${hostel['price']}';
                            if (value == 'Delete') {
                              _deleteHostel(hostelDetails);
                            } else if (value == 'Make Vacant') {
                              _updateHostelStatus(hostelDetails, 'available');
                            }
                          },
                          itemBuilder: (BuildContext context) {
                            return [
                              const PopupMenuItem<String>(
                                value: 'Delete',
                                child: Text('Delete'),
                              ),
                              if (hostel['status'] == 'occupied')
                                const PopupMenuItem<String>(
                                  value: 'Make Vacant',
                                  child: Text('Make Vacant'),
                                ),
                            ];
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: blockNameController,
                        decoration: const InputDecoration(labelText: 'Block Name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a block name';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: roomTypeController,
                        decoration: const InputDecoration(labelText: 'Room Type'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a room type';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a price';
                          }
                          return null;
                        },
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            List<String>? hostelStrings = prefs.getStringList('hostels') ?? [];
                            hostelStrings.add('${blockNameController.text},${roomTypeController.text},${priceController.text},available');
                            await prefs.setStringList('hostels', hostelStrings);
                            _loadHostels();
                            blockNameController.clear();
                            roomTypeController.clear();
                            priceController.clear();
                          }
                        },
                        child: const Text('Add Hostel'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
