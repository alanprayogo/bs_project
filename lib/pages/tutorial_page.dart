import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

class TutorialPage extends StatefulWidget {
  const TutorialPage({Key? key}) : super(key: key);

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  List<String> _detectedCards = [];
  TextEditingController _cardsController = TextEditingController();
  String? _selectedStrategy;
  final Map<String, String> strategyOptions = {
    'Opening': 'prec_opening',
    'Respon 1C': 'prec_respon_1c',
    'Respon 1D': 'prec_respon_1d',
  };
  Map<String, dynamic> _analysisResult = {};
  bool _isAnalyzing = false;

  // Fungsi bantu: format tampilan kartu dengan spasi
  String _formatCardsForDisplay(List<String> cards) {
    return cards.join(' ');
  }

  Future<void> _uploadImage(File imageFile) async {
    // final url = Uri.parse('http://192.168.18.6:8000/upload/');
    final url = Uri.parse('https://api2.komikgen.site/upload/');
    final request = http.MultipartRequest('POST', url);
    final multipartFile = await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
    );
    request.files.add(multipartFile);

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
          setState(() {
            _detectedCards = List<String>.from(responseData['cards']);
            _cardsController.text = _formatCardsForDisplay(_detectedCards);
          });
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

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _detectedCards.clear();
        _cardsController.clear();
        _selectedStrategy = null;
        _analysisResult.clear();
      });
      _uploadImage(File(image.path));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Tidak ada gambar dipilih")));
    }
  }

  Future<void> _takePicture() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _detectedCards.clear();
        _cardsController.clear();
        _selectedStrategy = null;
        _analysisResult.clear();
      });
      _uploadImage(File(image.path));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gambar tidak diambil")));
    }
  }

  Future<Map<String, String>> _runAnalysis() async {
    if (_isAnalyzing) return {};
    setState(() {
      _isAnalyzing = true;
    });

    final inputText = _cardsController.text.trim();
    if (inputText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Form kartu kosong")));
      setState(() {
        _isAnalyzing = false;
      });
      return {};
    }

    // Normalisasi input: ganti koma dengan spasi, lalu split
    final editedCards = inputText
        .replaceAll(',', ' ')
        .split(' ')
        .map((card) => card.trim())
        .where((card) => card.isNotEmpty)
        .toList();

    if (editedCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada kartu valid untuk dianalisis")),
      );
      setState(() {
        _isAnalyzing = false;
      });
      return {};
    }

    if (_selectedStrategy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan pilih strategi terlebih dahulu")),
      );
      setState(() {
        _isAnalyzing = false;
      });
      return {};
    }

    // final url = Uri.parse('http://192.168.18.6:8000/analisis');
    final url = Uri.parse('https://api2.komikgen.site/analisis');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'cards': editedCards, 'strategy': _selectedStrategy}),
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Analisis berhasil: ${data['message'] ?? 'OK'}"),
          ),
        );
        setState(() {
          _analysisResult = {
            'result': data['result'] ?? 'Unknown',
            'hcp': data['hcp']?.toString() ?? '0',
            'distribusi': data['distribusi'] ?? '0000',
          };
        });
        return {
          'result': data['result']?.toString() ?? 'Unknown',
          'hcp': data['hcp']?.toString() ?? '0',
          'distribusi': data['distribusi']?.toString() ?? '0000',
        };
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
    return {};
  }

  @override
  void dispose() {
    _cardsController.dispose();
    super.dispose();
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
              // Tombol Pilih & Ambil Gambar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.image),
                    label: const Text('Pilih Gambar'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _takePicture,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Ambil Gambar'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Preview gambar
              if (_selectedImage != null)
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_selectedImage!.path),
                        height: 300,
                        width: 300,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Dropdown Strategy
              if (_detectedCards.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: DropdownButtonFormField<String>(
                    value: _selectedStrategy,
                    hint: const Text("Pilih Strategi"),
                    items: strategyOptions.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.value,
                        child: Text(entry.key),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStrategy = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: "Strategi",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Form Input Kartu
              if (_detectedCards.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: _cardsController,
                    maxLines: 5,
                    minLines: 2,
                    decoration: InputDecoration(
                      labelText: "Kartu Terdeteksi (dapat diedit)",
                      border: OutlineInputBorder(),
                      hintText: "Contoh: Ace of Spades King of Hearts",
                    ),
                  ),
                ),

              // Tombol Reset dan Analisis
              if (_detectedCards.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                          _detectedCards.clear();
                          _cardsController.clear();
                          _selectedStrategy = null;
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
                  color: Colors.grey[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Rekomendasi",
                              style: TextStyle(color: Colors.white70),
                            ),
                            Text(
                              _analysisResult['result'] ?? '-',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Divider(color: Colors.white30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "HCP",
                              style: TextStyle(color: Colors.white70),
                            ),
                            Text(
                              _analysisResult['hcp'] ?? '-',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        Divider(color: Colors.white30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Distribusi",
                              style: TextStyle(color: Colors.white70),
                            ),
                            Text(
                              _analysisResult['distribusi'] ?? '-',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Margin bawah
              SizedBox(height: MediaQuery.of(context).padding.bottom + 40),
            ],
          ),
        ),
      ),
    );
  }
}
