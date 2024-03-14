import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DisplayHelpCrisisPage extends StatefulWidget {
  const DisplayHelpCrisisPage({Key? key}) : super(key: key);

  @override
  _DisplayHelpCrisisPageState createState() => _DisplayHelpCrisisPageState();
}

class _DisplayHelpCrisisPageState extends State<DisplayHelpCrisisPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('helpCrisis').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final crisis = snapshot.data!.docs[index];
              final crisisData = crisis.data() as Map<String, dynamic>;

              return Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                constraints: BoxConstraints(minHeight: 100),
                child: Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: SingleChildScrollView(
                    child: ListTile(
                      title: Text(
                        crisisData['name'] ?? 'No Name',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            crisisData['description'] ?? 'No Description',
                            style: TextStyle(fontSize: 16), // Set the font size
                            overflow: TextOverflow.visible, // Handle overflow
                          ),
                          SizedBox(height: 15),
                          _buildRow(
                              Icons.phone, '${crisisData['phoneNo'] ?? 'N/A'}'),
                          _buildRow(Icons.add_road,
                              '${crisisData['address'] ?? 'N/A'}'),
                          GestureDetector(
                            child: _buildLinkRow(Icons.link,
                                '${crisisData['websiteLink'] ?? 'N/A'}'),
                          ),
                          _buildRow(
                              Icons.person, '${crisisData['author'] ?? 'N/A'}'),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Widget _buildRow(IconData icon, String text) {
  return Row(
    children: [
      Icon(icon, size: 16),
      SizedBox(width: 5),
      Expanded(
        child: Text(
          text,
          style: TextStyle(fontSize: 16),
          overflow: TextOverflow.visible,
        ),
      ),
    ],
  );
}

Widget _buildLinkRow(IconData icon, String text) {
  return Row(
    children: [
      Icon(icon, size: 16),
      SizedBox(width: 5),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.blue,
            fontSize: 16,
            overflow: TextOverflow.visible,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    ],
  );
}