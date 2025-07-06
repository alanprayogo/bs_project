import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AnalisisBidPage extends StatefulWidget {
  static const String routeName = '/analisis';
  const AnalisisBidPage({super.key});

  @override
  State<AnalisisBidPage> createState() => _AnalisisBidPageState();
}

class _AnalisisBidPageState extends State<AnalisisBidPage> {
  final List<String> _cards = [];
  late String _currentCard;
  late String _strategy; // Menyimpan strategi yang dipilih
  final List<String> _ranks = [
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    'J',
    'Q',
    'K',
    'A',
  ];
  final List<String> _suits = ['♠', '♥', '♦', '♣'];

  void _addCardPart(String value) {
    setState(() {
      if (_currentCard.isEmpty && _ranks.contains(value)) {
        _currentCard = value;
      } else if (_currentCard.isNotEmpty && _suits.contains(value)) {
        if (_cards.length >= 13) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kartu pegangan sudah 13')),
          );
          _currentCard = '';
          return;
        }
        _currentCard += value;
        if (!_cards.contains(_currentCard)) {
          _cards.add(_currentCard);
        }
        _currentCard = '';
      }
    });
  }

  void _deleteLast() {
    setState(() {
      if (_currentCard.isNotEmpty) {
        _currentCard = '';
      } else if (_cards.isNotEmpty) {
        _cards.removeLast();
      }
    });
  }

  Future<Map<String, dynamic>> _analyzeWithStrategy(
    List<String> cards,
    String strategy,
  ) async {
    final url = Uri.parse('http://10.0.2.2:8000/analisis'); // emulator
    String convertCardUnicodeToSHDC(String card) {
      return card
          .replaceAll('♠', 'S')
          .replaceAll('♥', 'H')
          .replaceAll('♦', 'D')
          .replaceAll('♣', 'C');
    }

    List<String> convertedCards = cards.map(convertCardUnicodeToSHDC).toList();
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'cards': convertedCards, 'strategy': strategy}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'result': data['result']?.toString() ?? 'Unknown',
          'hcp': data['hcp']?.toString() ?? '0',
          'distribusi': data['distribusi']?.toString() ?? '0000',
        };
      } else {
        throw 'Server Error: ${response.statusCode}, Response: ${response.body}';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _submitAnalysis() async {
    if (_cards.length != 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harus tepat 13 kartu untuk analisis')),
      );
      return;
    }
    try {
      final result = await _analyzeWithStrategy(_cards, _strategy);
      setState(() {
        analysisData = {
          'Hasil Analisis': result['result']!,
          'HCP': '${result['hcp']} poin',
          'Distribusi': result['distribusi']!,
        };
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Analisis gagal: $e')));
    }
  }

  Map<String, String> analysisData = {}; // Inisialisasi awal

  @override
  void initState() {
    _currentCard = '';
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    _strategy = (args?['strategy'] as String?) ?? 'prec_opening';
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    String selectedBid = (args?['jenisBid'] as String?) ?? 'Opening';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisis Bid'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0E1431),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              child: Card(
                color: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Text(
                    selectedBid,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.lightBlue,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Kartu Pegangan
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (_cards.isEmpty && _currentCard.isEmpty)
                    const Text(
                      'Gunakan tombol di bawah untuk memasukkan kartu',
                      style: TextStyle(color: Colors.white60),
                    ),
                  for (var card in [
                    ..._cards,
                    if (_currentCard.isNotEmpty) _currentCard,
                  ])
                    Chip(
                      label: Text(card),
                      backgroundColor: Colors.blueGrey[800],
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          if (_currentCard.isEmpty) {
                            _cards.removeLast();
                          } else {
                            _currentCard = '';
                          }
                        });
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tombol Rank
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _ranks.map((rank) {
                bool isDisabled =
                    _currentCard.isNotEmpty || _cards.length >= 13;
                return ElevatedButton(
                  onPressed: isDisabled ? null : () => _addCardPart(rank),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDisabled
                        ? Colors.grey[600]
                        : Colors.grey[800],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: Text(rank),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Tombol Suit & Delete
            Wrap(
              spacing: 16,
              runAlignment: WrapAlignment.center,
              children: [
                ..._suits.map((suit) {
                  bool isDisabled = _currentCard.isEmpty || _cards.length >= 13;
                  return ElevatedButton.icon(
                    onPressed: isDisabled ? null : () => _addCardPart(suit),
                    icon: Text(
                      suit,
                      style: TextStyle(
                        color: suit == '♥' || suit == '♦'
                            ? Colors.red
                            : Colors.white,
                      ),
                    ),
                    label: const Text(''),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDisabled
                          ? Colors.grey[600]
                          : Colors.grey[800],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  );
                }).toList(),
                IconButton(
                  icon: const Icon(
                    Icons.backspace_outlined,
                    color: Colors.redAccent,
                  ),
                  onPressed: _deleteLast,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Tombol Analisis
            Center(
              child: ElevatedButton.icon(
                onPressed: _cards.isEmpty ? null : _submitAnalysis,
                icon: const Icon(Icons.search),
                label: const Text('Analisis'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cards.isEmpty ? Colors.grey : Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Hasil Analisis
            const Text(
              'Hasil Analisis:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // Container untuk Card Hasil Analisis
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 80),
              padding: EdgeInsets.zero,
              child: Card(
                color: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: analysisData.isEmpty
                        ? const Text(
                            'Hasil analisis akan ditampilkan di sini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white60),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: analysisData.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 140,
                                      child: Text(
                                        '${entry.key}:',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.lightBlue,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 64,
            ), // Tambahkan margin bawah agar bisa di-scroll
            Container(height: 120, color: Colors.transparent),
          ],
        ),
      ),
    );
  }
}
