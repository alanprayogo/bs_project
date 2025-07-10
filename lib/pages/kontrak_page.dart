import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class KontrakPage extends StatefulWidget {
  static const String routeName = '/kontrak';
  const KontrakPage({Key? key}) : super(key: key);

  @override
  State<KontrakPage> createState() => _KontrakPageState();
}

class _KontrakPageState extends State<KontrakPage> {
  final List<String> hand1 = [];
  final List<String> hand2 = [];

  late String _currentCard;

  final List<String> _ranks = [
    'A',
    'K',
    'Q',
    'J',
    '10',
    '9',
    '8',
    '7',
    '6',
    '5',
    '4',
    '3',
    '2',
  ];

  final List<String> _suits = ['♠', '♥', '♦', '♣'];

  void _addCardPart(String value) {
    setState(() {
      if (_currentCard.isEmpty && _ranks.contains(value)) {
        _currentCard = value;
      } else if (_currentCard.isNotEmpty && _suits.contains(value)) {
        if ((hand1.length + hand2.length) >= 26) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Total kartu sudah mencapai 26')),
          );
          _currentCard = '';
          return;
        }

        _currentCard += value;

        // Jika kartu belum ada, tambahkan pegangan 1 terlebih dahulu
        if (!_cardsContains(_currentCard)) {
          if (hand1.length < 13) {
            hand1.add(_currentCard);
          } else if (hand2.length < 13) {
            hand2.add(_currentCard);
          }
        }

        _currentCard = '';
      }
    });
  }

  bool _cardsContains(String card) {
    return hand1.contains(card) || hand2.contains(card);
  }

  void _deleteLast() {
    setState(() {
      if (_currentCard.isNotEmpty) {
        _currentCard = '';
      } else if (hand2.isNotEmpty) {
        hand2.removeLast();
      } else if (hand1.isNotEmpty) {
        hand1.removeLast();
      }
    });
  }

  Future<void> _submitRecommendation() async {
    if (hand1.length != 13 || hand2.length != 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harus tepat 13 kartu untuk setiap tim')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('http://10.0.2.2:8000/recommend');

      String convertCardUnicodeToSHDC(String card) {
        return card
            .replaceAll('♠', 'S')
            .replaceAll('♥', 'H')
            .replaceAll('♦', 'D')
            .replaceAll('♣', 'C')
            .replaceAll('10', 'T');
      }

      final convertedHand1 = hand1.map(convertCardUnicodeToSHDC).toList();
      final convertedHand2 = hand2.map(convertCardUnicodeToSHDC).toList();

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'hand1': convertedHand1, 'hand2': convertedHand2}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          analysisData = {
            'Rekomendasi': data['final_recommendation'] ?? '-',
            'Valid': data['valid'] == true ? 'Ya' : 'Tidak',
            'Skor Kepercayaan':
                '${data['confidence_score']?.toStringAsFixed(1) ?? 0.0}',
            'Alasan': (data['reasons'] as List)
                .map((e) => e.toString())
                .join('\n'),
            'Saran': (data['suggestions'] as List)
                .map((e) => e.toString())
                .join('\n'),
          };
        });
      } else {
        throw 'Server Error: ${response.statusCode}, Response: ${response.body}';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mendapatkan rekomendasi: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isLoading = false;
  Map<String, String> analysisData = {};

  @override
  void initState() {
    _currentCard = '';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kartu Pegangan 1
            Text(
              'Kartu Pegangan 1',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: hand1.isEmpty && _currentCard.isEmpty
                  ? const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Masukkan 13 kartu untuk Pegangan 1',
                        style: TextStyle(color: Colors.white60),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                          ),
                      itemCount: hand1.length,
                      itemBuilder: (context, index) {
                        return Card(
                          color: Colors.blueGrey[800],
                          child: Center(
                            child: Text(
                              hand1[index],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),

            // Kartu Pegangan 2
            Text(
              'Kartu Pegangan 2',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: hand2.isEmpty && _currentCard.isEmpty
                  ? const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Masukkan 13 kartu untuk Pegangan 2',
                        style: TextStyle(color: Colors.white60),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                          ),
                      itemCount: hand2.length,
                      itemBuilder: (context, index) {
                        return Card(
                          color: Colors.purple[800],
                          child: Center(
                            child: Text(
                              hand2[index],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 24),

            // Input Kartu UI (sama seperti AnalisisBidPage)
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _ranks
                      .where((r) => ['A', 'K', 'Q', 'J', '10'].contains(r))
                      .map((rank) {
                        bool isDisabled =
                            _currentCard.isNotEmpty ||
                            (hand1.length + hand2.length) >= 26;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: SizedBox(
                            width: 60,
                            child: ElevatedButton(
                              onPressed: isDisabled
                                  ? null
                                  : () => _addCardPart(rank),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDisabled
                                    ? Colors.grey[600]
                                    : Colors.grey[800],
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                                textStyle: const TextStyle(fontSize: 12),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(rank),
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _ranks
                      .where((r) => ['9', '8', '7', '6', '5'].contains(r))
                      .map((rank) {
                        bool isDisabled =
                            _currentCard.isNotEmpty ||
                            (hand1.length + hand2.length) >= 26;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: SizedBox(
                            width: 60,
                            child: ElevatedButton(
                              onPressed: isDisabled
                                  ? null
                                  : () => _addCardPart(rank),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDisabled
                                    ? Colors.grey[600]
                                    : Colors.grey[800],
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                                textStyle: const TextStyle(fontSize: 12),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(rank),
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _ranks
                      .where((r) => ['4', '3', '2'].contains(r))
                      .map((rank) {
                        bool isDisabled =
                            _currentCard.isNotEmpty ||
                            (hand1.length + hand2.length) >= 26;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: SizedBox(
                            width: 60,
                            child: ElevatedButton(
                              onPressed: isDisabled
                                  ? null
                                  : () => _addCardPart(rank),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDisabled
                                    ? Colors.grey[600]
                                    : Colors.grey[800],
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                                textStyle: const TextStyle(fontSize: 12),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(rank),
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ..._suits.map((suit) {
                  bool isDisabled =
                      _currentCard.isEmpty ||
                      (hand1.length + hand2.length) >= 26;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: SizedBox(
                      width: 60,
                      child: ElevatedButton.icon(
                        onPressed: isDisabled ? null : () => _addCardPart(suit),
                        icon: Text(
                          suit,
                          style: TextStyle(
                            color: suit == '♥' || suit == '♦'
                                ? Colors.red
                                : Colors.black,
                            fontSize: 12,
                          ),
                        ),
                        label: const Text(''),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDisabled
                              ? Colors.grey[600]
                              : Colors.grey[800],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  );
                }).toList(),

                // Tombol Delete
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: SizedBox(
                    width: 60,
                    child: ElevatedButton.icon(
                      onPressed:
                          hand1.isNotEmpty ||
                              hand2.isNotEmpty ||
                              _currentCard.isNotEmpty
                          ? _deleteLast
                          : null,
                      icon: const Icon(
                        Icons.backspace_outlined,
                        color: Colors.red,
                        size: 16,
                      ),
                      label: const Text(''),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            (hand1.isNotEmpty ||
                                hand2.isNotEmpty ||
                                _currentCard.isNotEmpty)
                            ? Colors.red[800]
                            : Colors.grey[800],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Tombol Reset dan Submit
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton.icon(
                    onPressed:
                        hand1.isNotEmpty ||
                            hand2.isNotEmpty ||
                            _currentCard.isNotEmpty
                        ? () {
                            setState(() {
                              hand1.clear();
                              hand2.clear();
                              _currentCard = '';
                              analysisData.clear();
                            });
                          }
                        : null,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          (hand1.isNotEmpty ||
                              hand2.isNotEmpty ||
                              _currentCard.isNotEmpty)
                          ? Colors.black
                          : Colors.grey[600],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                // Submit
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton.icon(
                    onPressed:
                        (hand1.length + hand2.length) < 26 || _isLoading
                        ? null
                        : _submitRecommendation,
                    icon: _isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(_isLoading ? 'Memproses...' : 'Kirim'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          (hand1.length + hand2.length) < 26 ||
                              _isLoading
                          ? Colors.grey
                          : Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Hasil Analisis
            Center(
              child: Text(
                'Hasil Rekomendasi:',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
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
                            'Hasil rekomendasi akan ditampilkan di sini.',
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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

            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }
}
