import 'package:cached_network_image/cached_network_image.dart';
import 'package:emindmatterssystem/screens/journal/DisplayAllJournal.dart';
import 'package:emindmatterssystem/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emindmatterssystem/screens/journal/JournalEntryModel.dart';
import 'package:intl/intl.dart';

class ViewSelectedJournalPage extends StatelessWidget {
  final String entryId;

  ViewSelectedJournalPage({required this.entryId});

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context); // Retrieve ThemeData here

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Your own memory",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: pShadeColor4,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => JournalListView()),
            );
          },
          icon: Icon(Icons.close, color: Colors.white,),
        ),
      ),
      body: FutureBuilder<JournalEntryData>(
        future: fetchJournalEntry(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: theme.textTheme.titleMedium!.copyWith(color: Colors.red)));
          } else if (snapshot.hasData) {
            JournalEntryData journalEntry = snapshot.data as JournalEntryData;
            return Scaffold(
              body: _buildViewForm(context, journalEntry),
              backgroundColor: journalEntry.backgroundColor, // Now it's in scope
            );
          } else {
            return Center(child: Text('No data found'));
          }
        },
      ),
    );
  }

  Future<JournalEntryData> fetchJournalEntry() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('journals')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('entries')
        .doc(entryId)
        .get();

    return JournalEntryData.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Widget _buildViewForm(BuildContext context, JournalEntryData journalEntry) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoSection('Title', journalEntry.title, 18, FontWeight.bold, context),
            _buildInfoSection('Description', journalEntry.description, 18, FontWeight.normal, context),
            _buildInfoSection('Tags', journalEntry.tags.join(', '), 18, FontWeight.normal, context),
            _buildInfoSection('Date', DateFormat('dd/MM/yyyy').format(journalEntry.date.toLocal()), 18, FontWeight.normal, context),
            _buildInfoSection('Time', journalEntry.time.format(context), 18, FontWeight.normal, context),
            SizedBox(height: 20),
            _buildImageGallery(context, journalEntry.images),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, double fontSize, FontWeight fontWeight, BuildContext context) {
    ThemeData theme = Theme.of(context);
    IconData iconData = _getIconForTitle(title);

    var titleTextStyle = theme.textTheme.titleLarge ?? TextStyle();
    var contentTextStyle = theme.textTheme.bodyMedium ?? TextStyle();

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconData, color: theme.primaryColor),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: titleTextStyle.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: contentTextStyle.copyWith(
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'title':
        return Icons.diamond_rounded;
      case 'description':
        return Icons.description;
      case 'tags':
        return Icons.tag;
      case 'date':
        return Icons.calendar_today;
      case 'time':
        return Icons.access_time;
      default:
        return Icons.info_outline;
    }
  }
  Widget _buildImageGallery(BuildContext context, List<String> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10),
        images.isNotEmpty
            ? GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(), // Prevents the GridView from scrolling independently
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Adjust the number of images per row
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1, // Keep it square or adjust as needed
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: images[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
              ),
            );
          },
        )
            : _buildInfoSection('No images available', '', 16, FontWeight.normal, context),
      ],
    );
  }
}