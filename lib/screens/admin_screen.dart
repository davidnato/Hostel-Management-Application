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
    _tabController = TabController(length: 2, vsync: this);
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
        };
      }).toList();
    });
  }

  Future<void> _deleteUser(String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? userStrings = prefs.getStringList('users') ?? [];
    userStrings.removeWhere((user) => user.contains(email));
    await prefs.setStringList('users', userStrings);
    _loadUsers(); // Reload the user list after deletion
  }

  Future<void> _deleteHostel(String hostelDetails) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? hostelStrings = prefs.getStringList('hostels') ?? [];
    hostelStrings.remove(hostelDetails);
    await prefs.setStringList('hostels', hostelStrings);
    _loadHostels(); // Refresh the hostel list after deletion
  }

  Future<void> _addHostel() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? hostelStrings = prefs.getStringList('hostels') ?? [];
    String hostelDetails = '${blockNameController.text},${roomTypeController.text},${priceController.text}';
    hostelStrings.add(hostelDetails);
    await prefs.setStringList('hostels', hostelStrings);
    blockNameController.clear();
    roomTypeController.clear();
    priceController.clear();
    _loadHostels(); // Refresh the hostel list after adding
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
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete User'),
                                content: Text('Are you sure you want to delete ${user['username']}?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      await _deleteUser(user['email']!);
                                    },
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
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
                    String hostelDetails = '${hostel['blockName']},${hostel['roomType']},${hostel['price']}';
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(hostel['blockName']!),
                        subtitle: Text('${hostel['roomType']} - \$${hostel['price']}'),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) async {
                            if (value == 'delete') {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Hostel'),
                                  content: Text('Are you sure you want to delete ${hostel['blockName']}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.of(context).pop();
                                        await _deleteHostel(hostelDetails);
                                      },
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text('Add Hostel', style: Theme.of(context).textTheme.headlineSmall),
                    Form(
                      key: _formKey,
                      child: Column(
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
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                await _addHostel();
                                setState(() {}); // Refresh the list
                              }
                            },
                            child: const Text('Add Hostel'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
