import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(AnonConfessApp());

class AnonConfessApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AnonConfess',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainScaffold(),
    );
  }
}

class Confession {
  final String id;
  final String text;
  final DateTime createdAt;
  final String pseudo;
  bool revealed;
  final List<Guess> guesses;

  Confession({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.pseudo,
    this.revealed = false,
    List<Guess>? guesses,
  }) : guesses = guesses ?? [];
}

class Guess {
  final String text;
  final DateTime time;
  Guess({required this.text}) : time = DateTime.now();
}

class MainScaffold extends StatefulWidget {
  @override
  _MainScaffoldState createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  final List<Confession> _confessions = List.generate(
    5,
    (i) => Confession(
      id: 'c\$i',
      text: sampleConfessions[i % sampleConfessions.length],
      createdAt: DateTime.now().subtract(Duration(hours: i * 5)),
      pseudo: randomPseudo(),
    ),
  );

  void _onNavTap(int idx) {
    setState(() => _selectedIndex = idx);
  }

  void _addConfession(String text) {
    final newConf = Confession(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text.trim(),
      createdAt: DateTime.now(),
      pseudo: randomPseudo(),
    );
    setState(() => _confessions.insert(0, newConf));
  }

  void _addGuess(String confessionId, String guessText) {
    setState(() {
      final conf = _confessions.firstWhere((c) => c.id == confessionId);
      conf.guesses.add(Guess(text: guessText.trim()));
    });
  }

  void _toggleReveal(String confessionId) {
    setState(() {
      final conf = _confessions.firstWhere((c) => c.id == confessionId);
      conf.revealed = !conf.revealed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [FeedPage(confessions: _confessions, onGuess: _addGuess, onToggleReveal: _toggleReveal),
    CreatePage(onPost: _addConfession),
    AboutPage()];

    return Scaffold(
      appBar: AppBar(
        title: Text('AnonConfess'),
        centerTitle: true,
        elevation: 2,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Post'),
          BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: 'About'),
        ],
      ),
    );
  }
}

class FeedPage extends StatelessWidget {
  final List<Confession> confessions;
  final void Function(String confessionId, String guessText) onGuess;
  final void Function(String confessionId) onToggleReveal;

  const FeedPage({required this.confessions, required this.onGuess, required this.onToggleReveal});

  @override
  Widget build(BuildContext context) {
    if (confessions.isEmpty) {
      return Center(child: Text('No confessions yet. Be the first to post!'));
    }

    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: confessions.length,
      itemBuilder: (context, index) {
        final c = confessions[index];
        return ConfessionCard(confession: c, onGuess: onGuess, onToggleReveal: onToggleReveal);
      },
    );
  }
}

class ConfessionCard extends StatefulWidget {
  final Confession confession;
  final void Function(String confessionId, String guessText) onGuess;
  final void Function(String confessionId) onToggleReveal;
  ConfessionCard({required this.confession, required this.onGuess, required this.onToggleReveal});

  @override
  _ConfessionCardState createState() => _ConfessionCardState();
}

class _ConfessionCardState extends State<ConfessionCard> with SingleTickerProviderStateMixin {
  final _guessController = TextEditingController();
  bool _showGuessField = false;

  @override
  void dispose() {
    _guessController.dispose();
    super.dispose();
  }

  Widget _buildMaskedText(String text) {
    // Simple mask: show only a few words and replace others with •••
    final parts = text.split(' ');
    if (widget.confession.revealed || parts.length <= 6) return Text(text, style: TextStyle(fontSize: 16));
    final show = parts.take(6).join(' ');
    return Text('$show •••', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.confession;
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  CircleAvatar(child: Text(c.pseudo[0].toUpperCase())),
                  SizedBox(width: 8),
                  Text(c.pseudo, style: TextStyle(fontWeight: FontWeight.bold)),
                ]),
                Text(_timeAgo(c.createdAt), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
            SizedBox(height: 12),
            _buildMaskedText(c.text),
            SizedBox(height: 12),
            if (c.revealed) ...[
              Divider(),
              Text('Full confession:', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              Text(c.text),
            ],
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _showGuessField = !_showGuessField),
                  icon: Icon(Icons.help_outline),
                  label: Text('Guess'),
                ),
                TextButton.icon(
                  onPressed: () => widget.onToggleReveal(c.id),
                  icon: Icon(Icons.visibility),
                  label: Text(c.revealed ? 'Hide' : 'Reveal'),
                ),
                TextButton.icon(
                  onPressed: () => _showShareSheet(context, c),
                  icon: Icon(Icons.share),
                  label: Text('Share'),
                ),
              ],
            ),
            if (_showGuessField)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _guessController,
                        decoration: InputDecoration(hintText: 'What do you think it means?'),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () {
                        final text = _guessController.text;
                        if (text.trim().isEmpty) return;
                        widget.onGuess(c.id, text);
                        _guessController.clear();
                        FocusScope.of(context).unfocus();
                        setState(() => _showGuessField = false);
                      },
                    )
                  ],
                ),
              ),
            if (c.guesses.isNotEmpty) ...[
              Divider(),
              Text('Guesses (${c.guesses.length})', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: c.guesses.reversed.map((g) => Padding(
                  padding: const EdgeInsets.symmetric(vertical:4.0),
                  child: Text('• ' + g.text, style: TextStyle(color: Colors.grey[800])),
                )).toList(),
              ),
            ]
          ],
        ),
      ),
    );
  }

  void _showShareSheet(BuildContext context, Confession c) {
    showModalBottomSheet(context: context, builder: (_) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Share confession', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              Text('You can copy the masked confession or share the app link.'),
              SizedBox(height: 12),
              Row(children: [
                ElevatedButton.icon(onPressed: () {
                  Navigator.of(context).pop();
                  final masked = widget.confession.revealed ? widget.confession.text : widget.confession.text.split(' ').take(6).join(' ') + ' •••';
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied: "$masked"')));
                }, icon: Icon(Icons.copy), label: Text('Copy')),
                SizedBox(width: 8),
                OutlinedButton.icon(onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pretend sharing...')));
                }, icon: Icon(Icons.share), label: Text('Share'))
              ],)
            ],
          ),
        ),
      );
    });
  }
}

class CreatePage extends StatefulWidget {
  final void Function(String text) onPost;
  CreatePage({required this.onPost});

  @override
  _CreatePageState createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  final _controller = TextEditingController();
  int _charCount = 0;
  final int _maxChars = 280;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _post() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onPost(text);
    _controller.clear();
    setState(() => _charCount = 0);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Posted anonymously.')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Share an anonymous thought', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Keep it short, mysterious, and respectful.'),
          SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              maxLength: _maxChars,
              onChanged: (v) => setState(() => _charCount = v.length),
              decoration: InputDecoration(
                hintText: 'Type your secret, confession, or mysterious clue...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_charCount / $_maxChars'),
              ElevatedButton(onPressed: _post, child: Text('Post anonymously')),
            ],
          )
        ],
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.indigo),
            SizedBox(height: 12),
            Text('A safe space to post anonymous thoughts, secrets, or confessions.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('Others can try to \"decode\" or guess the meaning. Great for Gen Z who love mystery + social interaction.', textAlign: TextAlign.center),
            SizedBox(height: 12),
            ElevatedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Be kind — respect others.'))), child: Text('Community Guidelines'))
          ],
        ),
      ),
    );
  }
}

// --- Helpers & sample data ---

String _timeAgo(DateTime at) {
  final diff = DateTime.now().difference(at);
  if (diff.inSeconds < 60) return '${diff.inSeconds}s';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  return '${diff.inDays}d';
}

final List<String> sampleConfessions = [
  "I keep a box of letters I never sent.",
  "Sometimes I sing to the plants and pretend they're judging me.",
  "I once pretended to be on a call to avoid someone on the bus.",
  "There is a name I still can't delete from my phone.",
  "I laugh at memes when I'm actually crying inside.",
];

String randomPseudo() {
  final adjectives = ['Quiet', 'Murmur', 'Velvet', 'Shadow', 'Echo', 'Pixel', 'Nova', 'Moss'];
  final nouns = ['Whisper', 'Riddle', 'Note', 'Post', 'Glitch', 'Cloud', 'Thread', 'Wisp'];
  final rnd = Random();
  return '${adjectives[rnd.nextInt(adjectives.length)]}${nouns[rnd.nextInt(nouns.length)]}${rnd.nextInt(99)}';
}
