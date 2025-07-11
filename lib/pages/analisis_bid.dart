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
    final url = Uri.parse('http://192.168.18.6:8000/analisis'); // emulator
    // final url = Uri.parse('https://api2.komikgen.site/analisis'); // deploy
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

    setState(() {
      _isLoading = true;
    });

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
              child: _cards.isEmpty && _currentCard.isEmpty
                  ? const Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Gunakan tombol di bawah untuk memasukkan kartu',
                        style: TextStyle(color: Colors.white60),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 6, // dikurangi dari 8
                            crossAxisSpacing: 6, // dikurangi dari 8
                          ),
                      itemCount:
                          _cards.length + (_currentCard.isNotEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < _cards.length) {
                          return Card(
                            color: Colors.blueGrey[800],
                            child: Center(
                              child: Text(
                                _cards[index],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14, // dikurangi dari 16
                                ),
                              ),
                            ),
                          );
                        } else if (_currentCard.isNotEmpty) {
                          return Card(
                            color: Colors.blueGrey[600],
                            child: Center(
                              child: Text(
                                _currentCard,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14, // dikurangi dari 16
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }
                        return Container(); // fallback
                      },
                    ),
            ),

            const SizedBox(height: 24),

            // Tombol Rank
            Column(
              children: [
                // Baris pertama: A, K, Q, J, 10
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _ranks
                      .where((r) => ['A', 'K', 'Q', 'J', '10'].contains(r))
                      // .toList()
                      // .reversed
                      .map((rank) {
                        bool isDisabled =
                            _currentCard.isNotEmpty || _cards.length >= 13;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2.0,
                          ), // dikurangi dari 4.0
                          child: SizedBox(
                            width:
                                60, // tambahkan lebar tetap untuk memperkecil tombol
                            child: ElevatedButton(
                              onPressed: isDisabled
                                  ? null
                                  : () => _addCardPart(rank),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDisabled
                                    ? Colors.grey[600]
                                    : Colors.grey[800],
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8, // dikurangi dari 12
                                  vertical: 10, // dikurangi dari 10
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                ), // font size lebih kecil
                                minimumSize: Size
                                    .zero, // untuk ukuran tombol lebih compact
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

                // Baris kedua: 9, 8, 7, 6, 5
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _ranks
                      .where((r) => ['9', '8', '7', '6', '5'].contains(r))
                      // .toList()
                      // .reversed
                      .map((rank) {
                        bool isDisabled =
                            _currentCard.isNotEmpty || _cards.length >= 13;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2.0,
                          ), // dikurangi
                          child: SizedBox(
                            width: 60, // lebar tetap
                            child: ElevatedButton(
                              onPressed: isDisabled
                                  ? null
                                  : () => _addCardPart(rank),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDisabled
                                    ? Colors.grey[600]
                                    : Colors.grey[800],
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8, // dikurangi
                                  vertical: 10, // dikurangi
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                ), // font lebih kecil
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

                // Baris ketiga: 4, 3, 2
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _ranks
                      .where((r) => ['4', '3', '2'].contains(r))
                      // .toList()
                      // .reversed
                      .map((rank) {
                        bool isDisabled =
                            _currentCard.isNotEmpty || _cards.length >= 13;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2.0,
                          ), // dikurangi dari 4.0
                          child: SizedBox(
                            width:
                                60, // lebar tetap untuk ukuran tombol lebih kecil
                            child: ElevatedButton(
                              onPressed: isDisabled
                                  ? null
                                  : () => _addCardPart(rank),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDisabled
                                    ? Colors.grey[600]
                                    : Colors.grey[800],
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8, // dikurangi dari 12
                                  vertical: 10, // dikurangi dari 10
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                ), // font size lebih kecil
                                minimumSize:
                                    Size.zero, // agar tombol lebih compact
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

            // Tombol Suit & Delete
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ..._suits.map((suit) {
                  bool isDisabled = _currentCard.isEmpty || _cards.length >= 13;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2.0,
                    ), // dikurangi dari 4.0
                    child: SizedBox(
                      width: 60, // lebar tetap untuk ukuran tombol lebih kecil
                      child: ElevatedButton.icon(
                        onPressed: isDisabled ? null : () => _addCardPart(suit),
                        icon: Text(
                          suit,
                          style: TextStyle(
                            color: suit == '♥' || suit == '♦'
                                ? Colors.grey[600]
                                : Colors.grey[800],
                            fontSize: 12, // font size lebih kecil
                          ),
                        ),
                        label: const Text(''),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDisabled
                              ? Colors.grey[600]
                              : Colors.grey[800],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6, // dikurangi dari 12
                            vertical: 6, // dikurangi dari 10
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2.0,
                  ), // dikurangi dari 4.0
                  child: SizedBox(
                    width: 60, // lebar tetap
                    child: ElevatedButton.icon(
                      onPressed: _cards.isNotEmpty || _currentCard.isNotEmpty
                          ? _deleteLast
                          : null,
                      icon: const Icon(
                        Icons.backspace_outlined,
                        color: Colors.red,
                        size: 16, // ukuran ikon disesuaikan
                      ),
                      label: const Text(''),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            (_cards.isNotEmpty || _currentCard.isNotEmpty)
                            ? Colors.red[800]
                            : Colors.grey[800],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6, // dikurangi dari 12
                          vertical: 6, // dikurangi dari 10
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

            // Tombol Analisis dan Reset
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tombol Reset
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton.icon(
                    onPressed: _cards.isNotEmpty || _currentCard.isNotEmpty
                        ? () {
                            setState(() {
                              _cards.clear();
                              _currentCard = '';
                              analysisData.clear();
                            });
                          }
                        : null,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          (_cards.isNotEmpty || _currentCard.isNotEmpty)
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

                // Tombol Analisis
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton.icon(
                    onPressed: _isLoading || _cards.length != 13
                        ? null
                        : _submitAnalysis,
                    icon: _isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.search),
                    label: Text(_isLoading ? 'Memproses...' : 'Analisis'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLoading || _cards.length != 13
                          ? Colors.grey
                          : Colors.blue,
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
                'Hasil Analisis:',
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
            const SizedBox(
              height: 64,
            )
          ],
        ),
      ),
    );
  }
}
