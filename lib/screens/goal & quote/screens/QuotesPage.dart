import 'package:animated_background/animated_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emindmatterssystem/utils/constant.dart';
import 'package:emindmatterssystem/screens/goal%20&%20quote/screens/DisplayAllGoals.dart';

class QuotesScreen extends StatefulWidget {
  @override
  _QuotesScreenState createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen>  with TickerProviderStateMixin{
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadAndSaveQuotes();
  }

  Future<List<dynamic>> fetchQuotes() async {
    if (_auth.currentUser == null) {
      throw Exception('User is not authenticated');
    }

    var urls = [
      'https://type.fit/api/quotes', // returns a list of quotes
      'https://zenquotes.io/api/random', // returns a single quote in a list
      'https://api.quotable.io/random', // returns a single quote
      'https://api.quotesnewtab.com/v1/quotes', // returns a list of quotes
    ];

    List<dynamic> quotes = [];

    for (var url in urls) {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data is List) {
          // If the API returns a list of quotes
          quotes.addAll(data);
        } else if (data is Map) {
          // If the API returns a single quote
          quotes.add(data);
        }
      } else {
        throw Exception('Failed to load quotes from API: $url');
      }
    }

    await saveQuotesToFirestore(quotes);
    return quotes;
  }

  Future<void> saveQuotesToFirestore(List<dynamic> quotes) async {
    if (_auth.currentUser == null) {
      throw Exception('User is not authenticated');
    }
    for (var quote in quotes) {
      if (quote['text'] is String &&
          quote['author'] is String &&
          quote['text'].isNotEmpty &&
          quote['author'].isNotEmpty) {
        await firestore.collection('quotes').add({
          'text': quote['text'],
          'author': quote['author'],
        });
      }
    }
  }

  Future<List<dynamic>> fetchQuotesFromFirestore() async {
    if (_auth.currentUser == null) {
      throw Exception('User is not authenticated');
    }
    QuerySnapshot snapshot = await firestore.collection('quotes').get();

    // Create a list to store the quote maps
    List<dynamic> quotes = [];

    // Iterate over the documents and add their data to the list
    for (var doc in snapshot.docs) {
      var data = doc.data();
      if (data is Map<String, dynamic>) {
        quotes.add(data);
      }
    }

    return quotes;
  }


  Future<List<dynamic>> _getUniqueQuotesForToday() async {
    final user = _auth.currentUser;

    if (user != null) {
      List<dynamic> allQuotes = await fetchQuotesFromFirestore();
      return allQuotes;
    } else {
      throw Exception('User is not authenticated');
    }
  }

  Future<void> _loadAndSaveQuotes() async {
    try {
      List<dynamic> quotes = await fetchQuotes();
      await saveQuotesToFirestore(quotes);
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColors,
      appBar: AppBar(
        backgroundColor: pShadeColor4,
        title: Text(
          "Embrace resilience!",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DisplayAllGoalsPage()),
            );
          },
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
      ),
      body: AnimatedBackground(
        behaviour:  RandomParticleBehaviour(
          options: ParticleOptions(
            spawnMaxRadius: 50,
            spawnMaxSpeed: 50,
            particleCount: 68,
            spawnMinSpeed: 10,
            minOpacity: 0.3,
            spawnOpacity: 0.4,
            baseColor: pShadeColor2,
          ),
        ),
        vsync: this,
        child: RefreshIndicator(
          onRefresh: _loadAndSaveQuotes,
          child: FutureBuilder<List<dynamic>>(
            future: _getUniqueQuotesForToday(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Something went wrong: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasData && snapshot.data!.isEmpty) {
                return Center(child: Text('No quotes available'));
              }
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 150.0), // Adjust the value as per your preference
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: snapshot.data?.length ?? 0,
                  itemBuilder: (context, index) {
                    var quote = snapshot.data![index];
                    return AnimatedQuoteCard(quote: quote, index: index);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class AnimatedQuoteCard extends StatefulWidget {
  final dynamic quote;
  final int index;

  AnimatedQuoteCard({required this.quote, required this.index});

  @override
  _AnimatedQuoteCardState createState() => _AnimatedQuoteCardState();
}

class _AnimatedQuoteCardState extends State<AnimatedQuoteCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: QuoteCard(quote: widget.quote),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class QuoteCard extends StatelessWidget {
  final dynamic quote;

  QuoteCard({required this.quote});

  @override
  Widget build(BuildContext context) {
    // Custom color palette
    final List<Color> cardColors = [
      Color(0xFFB3E5FC), // Light Blue
      Color(0xFFC8E6C9), // Light Green
      Color(0xFFF8BBD0), // Light Pink
      Color(0xFFFFCCBC), // Light Orange
      Color(0xFFD1C4E9), // Lavender
    ];
    final bgColor = cardColors[quote.hashCode % cardColors.length];

    return Container(
      width: MediaQuery.of(context).size.width * 0.95,
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgColor.withOpacity(0.9), bgColor.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 5),
            blurRadius: 10,
            spreadRadius: 2,
            color: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              quote['text'] ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.pacifico(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),
            Text(
              '- ' + (quote['author'] ?? '') + ' -',
              textAlign: TextAlign.center,
              style: GoogleFonts.merriweather(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
