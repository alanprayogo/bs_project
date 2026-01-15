import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

class SistemPage extends StatefulWidget {
  const SistemPage({Key? key}) : super(key: key);

  @override
  State<SistemPage> createState() => _SistemPageState();
}

class _SistemPageState extends State<SistemPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage1;
  XFile? _selectedImage2;
  List<String> _detectedCards1 = [];
  List<String> _detectedCards2 = [];
  TextEditingController _cardsController1 = TextEditingController();
  TextEditingController _cardsController2 = TextEditingController();
  Map<String, String> _analysisResult = {};
  bool _isAnalyzing = false;

  // Fungsi bantu: format tampilan dengan spasi
  String _formatForDisplay(List<String> cards) {
    return cards.join(' ');
  }

  // Konversi kartu seperti 10S -> TS untuk backend
  String _convertCardToServerFormat(String card) {
    if (card.length == 3 && card.startsWith('10')) {
      return 'T${card[2]}';
    }
    return card;
  }

  // Upload gambar ke backend
  Future<void> _uploadImage(File imageFile, int handNumber) async {
    // final url = Uri.parse('http://192.168.18.6:8000/upload_hand/');
    final url = Uri.parse('https://vps.ncnd.store/bca/api/upload_hand/');
    final request = http.MultipartRequest('POST', url);
    final multipartFile = await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
    );
    request.files.add(multipartFile);
    request.fields['hand_number'] = '$handNumber';

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final respBody = await http.Response.fromStream(response);
        final responseData = json.decode(respBody.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload berhasil: ${responseData['message']}"),
          ),
        );
        if (responseData.containsKey('cards') &&
            responseData['cards'] is List) {
          final cards = List<String>.from(responseData['cards']);
          if (handNumber == 1) {
            setState(() {
              _detectedCards1 = cards;
              _cardsController1.text = _formatForDisplay(cards);
            });
          } else {
            setState(() {
              _detectedCards2 = cards;
              _cardsController2.text = _formatForDisplay(cards);
            });
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Tidak ada kartu terdeteksi untuk hand $handNumber",
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload gagal: ${response.reasonPhrase}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // Pilih gambar untuk hand 1
  Future<void> _pickImage1() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage1 = image;
        _detectedCards1.clear();
        _cardsController1.clear();
      });
      _uploadImage(File(image.path), 1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada gambar dipilih untuk hand 1")),
      );
    }
  }

  // Pilih gambar untuk hand 2
  Future<void> _pickImage2() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage2 = image;
        _detectedCards2.clear();
        _cardsController2.clear();
      });
      _uploadImage(File(image.path), 2);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada gambar dipilih untuk hand 2")),
      );
    }
  }

  // Analisis kontrak dari dua tangan
  Future<void> _runAnalysis() async {
    if (_isAnalyzing) return;
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final input1 = _cardsController1.text.trim();
      final input2 = _cardsController2.text.trim();

      if (input1.isEmpty || input2.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kedua tangan harus berisi kartu")),
        );
        return;
      }

      // Normalisasi input: ganti koma dengan spasi, lalu split
      final hand1 = input1
          .replaceAll(',', ' ')
          .split(' ')
          .map((card) => card.trim())
          .where((card) => card.isNotEmpty)
          .map(_convertCardToServerFormat)
          .toList();

      final hand2 = input2
          .replaceAll(',', ' ')
          .split(' ')
          .map((card) => card.trim())
          .where((card) => card.isNotEmpty)
          .map(_convertCardToServerFormat)
          .toList();

      if (hand1.isEmpty || hand2.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Tidak ada kartu valid untuk dianalisis"),
          ),
        );
        return;
      }

      // final url = Uri.parse('http://192.168.18.6:8000/recommend');
      final url = Uri.parse('https://vps.ncnd.store/bca/api/recommend');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'hand1': hand1, 'hand2': hand2}),
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['result'];
        if (result == null) throw Exception("Hasil tidak ditemukan");

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Analisis berhasil!")));

        setState(() {
          _analysisResult = {
            'early_contract': result['early_predicted_contract'] ?? '-',
            'early_confidence':
                '${(result['early_confidence_score'] ?? 0.0).toStringAsFixed(1)}%',
            'final_contract': result['predicted_contract'] ?? '-',
            'final_confidence':
                '${(result['confidence_score'] ?? 0.0).toStringAsFixed(1)}%',
            'hand1_hcp': result['hand1_hcp']?.toString() ?? '-',
            'hand2_hcp': result['hand2_hcp']?.toString() ?? '-',
            'total_hcp': result['total_hcp']?.toString() ?? '-',
            'suit_dist': result['suit_dist']?.toString() ?? '-',
          };
        });
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = "Server Error";
        if (errorData is Map && errorData.containsKey("detail")) {
          if (errorData["detail"] is List && errorData["detail"].isNotEmpty) {
            errorMessage =
                errorData["detail"][0]["msg"] ?? "Error tidak diketahui";
          } else {
            errorMessage = errorData["detail"];
          }
        } else {
          errorMessage = response.reasonPhrase ?? "Error tidak diketahui";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Analisis gagal: $errorMessage")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  void dispose() {
    _cardsController1.dispose();
    _cardsController2.dispose();
    super.dispose();
  }

  // Helper untuk membuat baris hasil
  Widget _buildResultRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white70)),
        Flexible(
          child: Text(
            value,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Tombol Upload Gambar 1
              ElevatedButton.icon(
                onPressed: _pickImage1,
                icon: const Icon(Icons.image),
                label: const Text('Pilih Gambar 1'),
              ),
              const SizedBox(height: 20),

              // Preview Gambar 1
              if (_selectedImage1 != null)
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_selectedImage1!.path),
                        height: 250,
                        width: 250,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Form Input Kartu 1
              if (_detectedCards1.isNotEmpty || _selectedImage1 != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: _cardsController1,
                    maxLines: 5,
                    minLines: 2,
                    decoration: InputDecoration(
                      labelText: "Kartu Terdeteksi - Hand 1",
                      border: OutlineInputBorder(),
                      hintText: "Contoh: AS KH QD JC",
                    ),
                  ),
                ),

              const SizedBox(height: 30),

              // Tombol Upload Gambar 2
              ElevatedButton.icon(
                onPressed: _pickImage2,
                icon: const Icon(Icons.image),
                label: const Text('Pilih Gambar 2'),
              ),
              const SizedBox(height: 20),

              // Preview Gambar 2
              if (_selectedImage2 != null)
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_selectedImage2!.path),
                        height: 250,
                        width: 250,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Form Input Kartu 2
              if (_detectedCards2.isNotEmpty || _selectedImage2 != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: _cardsController2,
                    maxLines: 5,
                    minLines: 2,
                    decoration: InputDecoration(
                      labelText: "Kartu Terdeteksi - Hand 2",
                      border: OutlineInputBorder(),
                      hintText: "Contoh: AS KH QD JC",
                    ),
                  ),
                ),

              const SizedBox(height: 30),

              // Tombol Reset dan Analisis
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedImage1 = null;
                        _selectedImage2 = null;
                        _detectedCards1.clear();
                        _detectedCards2.clear();
                        _cardsController1.clear();
                        _cardsController2.clear();
                        _analysisResult.clear();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text("Reset"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _runAnalysis,
                    icon: _isAnalyzing
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_graph),
                    label: Text(_isAnalyzing ? "Memproses..." : "Analisis"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAnalyzing ? Colors.grey : null,
                    ),
                  ),
                ],
              ),

              // Hasil Analisis
              if (_analysisResult.isNotEmpty) ...[
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Hasil Analisis:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildResultRow(
                          "Kontrak Awal",
                          "${_analysisResult['early_contract']} (${_analysisResult['early_confidence']})",
                        ),
                        Divider(color: Colors.white30),
                        _buildResultRow(
                          "Kontrak Akhir",
                          "${_analysisResult['final_contract']} (${_analysisResult['final_confidence']})",
                        ),
                        Divider(color: Colors.white30),
                        _buildResultRow(
                          "HCP Tangan 1",
                          "${_analysisResult['hand1_hcp']}",
                        ),
                        Divider(color: Colors.white30),
                        _buildResultRow(
                          "HCP Tangan 2",
                          "${_analysisResult['hand2_hcp']}",
                        ),
                        Divider(color: Colors.white30),
                        _buildResultRow(
                          "Total HCP",
                          "${_analysisResult['total_hcp']}",
                        ),
                        Divider(color: Colors.white30),
                        _buildResultRow(
                          "Distribusi Suit",
                          "${_analysisResult['suit_dist']}",
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
