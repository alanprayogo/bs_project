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

  Map<String, dynamic> _analysisResult = {};

  String _convertCardToServerFormat(String card) {
    if (card.length == 3 && card.startsWith('10')) {
      return 'T${card[2]}';
    }
    return card;
  }

  Future<void> _uploadImage(File imageFile, int handNumber) async {
    final url = Uri.parse('http://192.168.18.6:8000/upload_hand/');

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
          setState(() {
            if (handNumber == 1) {
              _detectedCards1 = List<String>.from(responseData['cards']);
              _cardsController1.text = _detectedCards1.join(', ');
            } else {
              _detectedCards2 = List<String>.from(responseData['cards']);
              _cardsController2.text = _detectedCards2.join(', ');
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Tidak ada data kartu untuk hand_$handNumber"),
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
        SnackBar(content: Text("Tidak ada gambar dipilih untuk hand 1")),
      );
    }
  }

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
        SnackBar(content: Text("Tidak ada gambar dipilih untuk hand 2")),
      );
    }
  }

  Future<void> _runAnalysis() async {
    final rawInput1 = _cardsController1.text.trim();
    final rawInput2 = _cardsController2.text.trim();

    final hand1 = rawInput1
        .split(',')
        .map((card) => card.trim())
        .where((card) => card.isNotEmpty)
        .map(_convertCardToServerFormat)
        .toList();

    final hand2 = rawInput2
        .split(',')
        .map((card) => card.trim())
        .where((card) => card.isNotEmpty)
        .map(_convertCardToServerFormat)
        .toList();

    if (hand1.isEmpty || hand2.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Kedua form harus berisi kartu")));
      return;
    }

    final url = Uri.parse('http://192.168.18.6:8000/recommend');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'hand1': hand1, 'hand2': hand2}),
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
            'result': data['final_recommendation'] ?? 'Unknown',
            'valid': data['valid'] == true ? 'Ya' : 'Tidak',
            'confidence': '${(data['confidence_score'] ?? 0.0)}',
            'reasons': (data['reasons'] ?? []).join('\n'),
            'suggestions': (data['suggestions'] ?? []).join('\n'),
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
      rethrow;
    }
  }

  @override
  void dispose() {
    _cardsController1.dispose();
    _cardsController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text("Sistem Page")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Tombol Upload Gambar 1
              ElevatedButton.icon(
                onPressed: _pickImage1,
                icon: Icon(Icons.image),
                label: Text('Pilih Gambar 1'),
              ),
              SizedBox(height: 20),

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

              SizedBox(height: 20),

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
                      hintText: "Contoh: Ace of Spades, King of Hearts",
                    ),
                  ),
                ),

              SizedBox(height: 20),

              // Tombol Upload Gambar 2
              ElevatedButton.icon(
                onPressed: _pickImage2,
                icon: Icon(Icons.image),
                label: Text('Pilih Gambar 2'),
              ),
              SizedBox(height: 20),

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

              SizedBox(height: 20),

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
                      hintText: "Contoh: Ace of Spades, King of Hearts",
                    ),
                  ),
                ),

              SizedBox(height: 20),

              // Tombol Analisis
              ElevatedButton.icon(
                onPressed: _runAnalysis,
                icon: Icon(Icons.auto_graph),
                label: Text("Analisis"),
              ),

              // Hasil Analisis
              if (_analysisResult.isNotEmpty) ...[
                SizedBox(height: 20),
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
                SizedBox(height: 10),
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
                              "Valid",
                              style: TextStyle(color: Colors.white70),
                            ),
                            Text(
                              _analysisResult['valid'] ?? '-',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        Divider(color: Colors.white30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Skor Kepercayaan",
                              style: TextStyle(color: Colors.white70),
                            ),
                            Text(
                              _analysisResult['confidence'] ?? '-',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        Divider(color: Colors.white30),
                        Text(
                          "Alasan:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          _analysisResult['reasons'] ?? '-',
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Saran:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          _analysisResult['suggestions'] ?? '-',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              SizedBox(height: MediaQuery.of(context).padding.bottom + 40),
            ],
          ),
        ),
      ),
    );
  }
}
