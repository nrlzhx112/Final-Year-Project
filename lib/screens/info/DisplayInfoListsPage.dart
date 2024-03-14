import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constant.dart'; // Assuming you have the constant.dart for colors and styles

class DisplayInfoListsPage extends StatefulWidget {
  const DisplayInfoListsPage({Key? key}) : super(key: key);

  @override
  _DisplayInfoListsPageState createState() => _DisplayInfoListsPageState();
}

class _DisplayInfoListsPageState extends State<DisplayInfoListsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('topics').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final topic = snapshot.data!.docs[index];
              final topicData = topic.data() as Map<String, dynamic>;

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
                        topicData['title'] ?? 'No Title',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(topicData['description'] ?? 'No Description'),
                          SizedBox(height: 15),
                          Row(
                            children: [
                              Icon(Icons.person, size: 16),
                              SizedBox(width: 5),
                              Text('${topicData['author'] ?? 'N/A'}'),
                            ],
                          ),
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
