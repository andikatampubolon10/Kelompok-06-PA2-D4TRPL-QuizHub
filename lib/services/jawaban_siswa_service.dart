  import 'dart:convert';
  import 'package:http/http.dart' as http;
  import 'package:shared_preferences/shared_preferences.dart';

  class JawabanSiswa {
    final String jawabanSiswa;
    final int idSoal;
    final int idSiswa;
    final int? idJawabanSoal;

    JawabanSiswa({
      required this.jawabanSiswa,
      required this.idSoal,
      required this.idSiswa,
      this.idJawabanSoal,
    });

    Map<String, dynamic> toJson() {
      return {
        'jawaban_siswa': jawabanSiswa,
        'id_soal': idSoal,
        'id_siswa': idSiswa,
        'id_jawaban_soal': idJawabanSoal,
      };
    }
  }

  class JawabanSiswaService {
    // Base URL for the API
    final String baseUrl = 'https://kelompok06-trpl23-api-golang-production.up.railway.app/api';

    // Add this method to check if a student has already taken a quiz
    

    // Create a single jawaban siswa
    Future<bool> createJawabanSiswa(JawabanSiswa jawabanSiswa) async {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/jawaban-siswa'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(jawabanSiswa.toJson()),
        );

        if (response.statusCode == 201) {
          print('Jawaban siswa created successfully');
          return true;
        } else {
          print('Failed to create jawaban siswa: ${response.body}');
          return false;
        }
      } catch (e) {
        print('Error creating jawaban siswa: $e');
        return false;
      }
    }

    Future<double> getCalculatedScore(String idUjian, int idSiswa) async {
      try {
        final response = await http.get(
          Uri.parse('https://kelompok06-trpl23-api-golang-production.up.railway.app/nilai-siswa/$idUjian/$idSiswa'),
        );
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['total_score']?.toDouble() ?? 0.0;
        } else {
          print('Failed to get calculated score: ${response.statusCode}');
          print('Response body: ${response.body}');
          
          // If the server-side calculation fails, fall back to client-side calculation
          return await calculateTotalScore(idUjian, idSiswa);
        }
      } catch (e) {
        print('Error getting calculated score: $e');
        // Fall back to client-side calculation
        return await calculateTotalScore(idUjian, idSiswa);
      }
    }

    Future<double> calculateScoreClientSide(String idUjian, int idSiswa, List<Map<String, dynamic>> questions, List<String?> selectedAnswers) async {
      try {
        double totalScore = 0.0;
        
        // Create a map to store the submitted answers
        Map<int, int> submittedAnswers = {}; // Map of idSoal to idJawabanSoal
        
        // Process each question and selected answer
        for (int i = 0; i < questions.length; i++) {
          if (selectedAnswers[i] == null) continue;
          
          final question = questions[i];
          final selectedAnswer = selectedAnswers[i]!;
          
          // Get question ID
          int idSoal;
          try {
            idSoal = int.parse(question['id'] ?? '0');
          } catch (e) {
            print('Error parsing question ID: ${question['id']}');
            continue;
          }
          
          // Find the selected answer's idJawabanSoal
          int? idJawabanSoal;
          bool isCorrect = false;
          double nilaiPerSoal = 0.0;
          
          // Get nilai_per_soal from the question data if available
          try {
            if (question.containsKey('nilai_per_soal')) {
              nilaiPerSoal = double.parse(question['nilai_per_soal'].toString());
            }
          } catch (e) {
            print('Error parsing nilai_per_soal: $e');
          }
          
          // Process based on question type
          if (question['id_tipe_soal'] == 1 || question['id_tipe_soal'] == 2) { // Multiple Choice or True/False
            final jawabanListData = question['jawaban_list'] as List<dynamic>? ?? [];
            
            for (var jawaban in jawabanListData) {
              final teksJawaban = jawaban['teks_jawaban']?.toString() ?? 
                                jawaban['jawaban']?.toString() ?? 
                                jawaban['text']?.toString();
              
              if (teksJawaban == selectedAnswer) {
                idJawabanSoal = jawaban['id_jawaban_soal'] ?? jawaban['id'];
                isCorrect = jawaban['benar'] == true;
                break;
              }
            }
          }
          
          if (idJawabanSoal != null) {
            submittedAnswers[idSoal] = idJawabanSoal;
            
            // If we know the answer is correct and have nilai_per_soal, add to score
            if (isCorrect && nilaiPerSoal > 0) {
              totalScore += nilaiPerSoal;
              print('Added $nilaiPerSoal for correct answer on question $idSoal');
            }
          }
        }
        
        // If we couldn't calculate the score from the local data, fetch from server
        if (totalScore == 0.0 && submittedAnswers.isNotEmpty) {
          // Wait a moment for the answers to be saved on the server
          await Future.delayed(Duration(seconds: 1));
          
          // Fetch the jawaban_siswa records for this student and exam
          final response = await http.get(
            Uri.parse('https://kelompok06-trpl23-api-golang-production.up.railway.app/jawaban-siswa/$idUjian/$idSiswa'),
          );
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final List<dynamic> jawabanList = data['data'] ?? [];
            
            for (var jawaban in jawabanList) {
              final int idSoal = jawaban['id_soal'] ?? 0;
              final int idJawabanSoal = jawaban['id_jawaban_soal'] ?? 0;
              
              if (idSoal <= 0 || idJawabanSoal <= 0) continue;
              
              // Find the corresponding question
              Map<String, dynamic>? question;
              for (var q in questions) {
                if (q['id'] == idSoal.toString()) {
                  question = q;
                  break;
                }
              }
              
              if (question == null) continue;
              
              // Find if the answer is correct
              bool isCorrect = false;
              double nilaiPerSoal = 0.0;
              
              // Get nilai_per_soal
              try {
                if (question.containsKey('nilai_per_soal')) {
                  nilaiPerSoal = double.parse(question['nilai_per_soal'].toString());
                } else {
                  // Fetch nilai_per_soal from server
                  final soalResponse = await http.get(
                    Uri.parse('https://kelompok06-trpl23-api-golang-production.up.railway.app/soal/$idSoal'),
                  );
                  
                  if (soalResponse.statusCode == 200) {
                    final soalData = jsonDecode(soalResponse.body);
                    nilaiPerSoal = double.tryParse(soalData['nilai_per_soal']?.toString() ?? '0') ?? 0.0;
                  }
                }
              } catch (e) {
                print('Error getting nilai_per_soal: $e');
                continue;
              }
              
              // Check if the answer is correct
              final jawabanListData = question['jawaban_list'] as List<dynamic>? ?? [];
              for (var jawab in jawabanListData) {
                if (jawab['id_jawaban_soal'] == idJawabanSoal) {
                  isCorrect = jawab['benar'] == true;
                  break;
                }
              }
              
              // If correct, add to score
              if (isCorrect) {
                totalScore += nilaiPerSoal;
                print('Added $nilaiPerSoal for correct answer on question $idSoal');
              }
            }
          }
        }
        
        return totalScore;
      } catch (e) {
        print('Error calculating score client-side: $e');
        return 0.0;
      }
    }

    Future<bool> hasStudentTakenQuiz(String idUjian, int idSiswa) async {
    try {
      // First try the dedicated endpoint
      final response = await http.post(
        Uri.parse('$baseUrl/check-attempt-ujian'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_ujian': idUjian,
          'id_siswa': idSiswa,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['hasAttempted'] == true;
      }

      // If that fails, try the alternative endpoint
      final altResponse = await http.get(
        Uri.parse('$baseUrl/check-attempt-ujian/$idUjian/$idSiswa'),
      );

      if (altResponse.statusCode == 200) {
        final data = jsonDecode(altResponse.body);
        return data['hasAttempted'] == true;
      }

      // If both fail, check directly in the database
      return await checkAttemptAlternative(idUjian, idSiswa);
    } catch (e) {
      print('Error checking quiz attempt: $e');
      // Fallback to alternative method
      return await checkAttemptAlternative(idUjian, idSiswa);
    }
  }

  // Alternative method to check if student has taken the quiz
  Future<bool> checkAttemptAlternative(String idUjian, int idSiswa) async {
    try {
      // Check if there are any existing answers for this student and quiz
      final response = await http.get(
        Uri.parse('$baseUrl/jawaban-siswa/ujian/$idUjian/siswa/$idSiswa'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> answers = data['data'] ?? [];
        return answers.isNotEmpty; // If there are answers, student has taken the quiz
      } else if (response.statusCode == 404) {
        // No answers found, student hasn't taken the quiz
        return false;
      } else {
        print('Failed to check quiz attempt (alternative): ${response.statusCode}');
        
        // Check if there's a score record as a last resort
        final scoreResponse = await http.get(
          Uri.parse('$baseUrl/nilai-siswa/$idUjian/$idSiswa'),
        );
        
        if (scoreResponse.statusCode == 200) {
          final scoreData = jsonDecode(scoreResponse.body);
          // If there's a score, student has taken the quiz
          return scoreData != null && scoreData.isNotEmpty;
        }
        
        // If all checks fail, assume student hasn't taken the quiz
        return false;
      }
    } catch (e) {
      print('Error in alternative quiz attempt check: $e');
      // If we can't determine, default to false to allow the student to take the quiz
      return false;
    }
  }


    Future<double> calculateTotalScore(String idUjian, int idSiswa) async {
      try {
        double totalScore = 0.0;
        
        // First, get all the student's answers for this exam
        final response = await http.get(
          Uri.parse('https://kelompok06-trpl23-api-golang-production.up.railway.app/jawaban-siswa/$idUjian/$idSiswa'),
        );
        
        if (response.statusCode != 200) {
          print('Failed to get jawaban siswa: ${response.statusCode}');
          return 0.0;
        }
        
        final data = jsonDecode(response.body);
        final List<dynamic> jawabanList = data['data'] ?? [];
        
        if (jawabanList.isEmpty) {
          print('No answers found for calculation');
          return 0.0;
        }
        
        // Process each answer
        for (var jawaban in jawabanList) {
          final int idJawabanSoal = jawaban['id_jawaban_soal'] ?? 0;
          final int idSoal = jawaban['id_soal'] ?? 0;
          
          if (idJawabanSoal <= 0 || idSoal <= 0) continue;
          
          // Get the jawaban_soal to check if the answer is correct
          final jawabanSoalResponse = await http.get(
            Uri.parse('https://kelompok06-trpl23-api-golang-production.up.railway.app/jawaban-soal/$idJawabanSoal'),
          );
          
          if (jawabanSoalResponse.statusCode != 200) {
            print('Failed to get jawaban_soal: ${jawabanSoalResponse.statusCode}');
            continue;
          }
          
          final jawabanSoalData = jsonDecode(jawabanSoalResponse.body);
          final bool isCorrect = jawabanSoalData['benar'] ?? false;
          
          if (!isCorrect) continue; // Skip if the answer is not correct
          
          // Get the soal to get the nilai_per_soal
          final soalResponse = await http.get(
            Uri.parse('https://kelompok06-trpl23-api-golang-production.up.railway.app/soal/$idSoal'),
          );
          
          if (soalResponse.statusCode != 200) {
            print('Failed to get soal: ${soalResponse.statusCode}');
            continue;
          }
          
          final soalData = jsonDecode(soalResponse.body);
          final double nilaiPerSoal = double.tryParse(soalData['nilai_per_soal']?.toString() ?? '0') ?? 0.0;
          
          // Add the nilai_per_soal to the total score
          totalScore += nilaiPerSoal;
          print('Added $nilaiPerSoal for correct answer on question $idSoal');
        }
        
        return totalScore;
      } catch (e) {
        print('Error calculating total score: $e');
        return 0.0;
      }
    }

    Future<Map<int, double>> calculateScoresByTipeUjian(String idKursus, int idSiswa) async {
  try {
    print("Requesting total score for idKursus: $idKursus, idSiswa: $idSiswa");
    final response = await http.get(
      Uri.parse('https://kelompok06-trpl23-api-golang-production.up.railway.app/sum_nilai_ujian_kursus/$idKursus/$idSiswa'),
    );

    print("Response status: ${response.statusCode}");
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final Map<int, double> scores = {};

      if (data['nilai_total_per_tipe_ujian'] != null) {
        Map.from(data['nilai_total_per_tipe_ujian']).forEach((key, value) {
          scores[int.parse(key.toString())] = double.parse(value.toString());
        });
      }
      return scores;
    } else {
      print("Failed to calculate total score: ${response.body}");
      throw Exception('Failed to calculate total score');
    }
  } catch (e) {
    print("Error calculating total score: $e");
    return {};
  }
}


Future<bool> submitScoreToNilaiKursus(double score, int idTipeUjian, int idSiswa, String idKursus) async {
  try {
    print("Submitting score: $score for tipe_ujian: $idTipeUjian, idSiswa: $idSiswa, idKursus: $idKursus");
    final response = await http.post(
      Uri.parse('https://kelompok06-trpl23-api-golang-production.up.railway.app/nilai_kursus/$idKursus/$idSiswa'),  // Use idKursus here in the URL
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'nilai_tipe_ujian': score,
        'id_tipe_ujian': idTipeUjian,
      }),
    );

    print("Response status: ${response.statusCode}");
    if (response.statusCode == 200) {
      print("Score successfully submitted");
      return true;
    } else {
      print("Failed to submit score: ${response.body}");
      return false;
    }
  } catch (e) {
    print("Error submitting score: $e");
    return false;
  }
}

Future<bool> submitCalculatedScoreToNilai(double totalScore, String idKursus, int idSiswa) async {
    try {
      final response = await http.post(
        Uri.parse('https://kelompok06-trpl23-api-golang-production.up.railway.app/nilai/$idKursus/$idSiswa'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nilai_tipe_ujian': totalScore,
        }),
      );

      if (response.statusCode == 200) {
        print("Nilai berhasil disimpan di nilai_kursus");
        return true;
      } else {
        print("Gagal menyimpan nilai: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error menyimpan nilai: $e");
      return false;
    }
  }


    Future<double> getTotalNilaiSiswa(String idUjian, String idSiswa) async {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/total-nilai-by-ujian/$idUjian/$idSiswa'),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['nilai_total']?.toDouble() ?? 0.0; // Extract total score from response
        } else {
          print('Failed to get total score: ${response.body}');
          return 0.0;
        }
      } catch (e) {
        print('Error getting total score: $e');
        return 0.0;
      }
    }

    // Method to submit score to 'tipe_nilai' table
    Future<bool> submitNilaiToTipeNilai(double nilai, int idTipeUjian, int idSiswa, int idUjian) async {
      try {
        // Validate input parameters
        if (idTipeUjian <= 0) {
          print('WARNING: idTipeUjian is invalid: $idTipeUjian');
          
          // Try to fetch the correct idTipeUjian from the ujian data
          try {
            final ujianResponse = await http.get(
              Uri.parse('$baseUrl/ujian/$idUjian'),
            );
            
            if (ujianResponse.statusCode == 200) {
              final ujianData = jsonDecode(ujianResponse.body);
              // Extract tipe_ujian from the response
              if (ujianData['tipe_ujian'] != null) {
                idTipeUjian = ujianData['tipe_ujian'];
                print('Retrieved idTipeUjian from server: $idTipeUjian');
              } else {
                print('Server returned ujian data but tipe_ujian is null');
              }
            } else {
              print('Failed to fetch ujian data: ${ujianResponse.statusCode}');
            }
          } catch (e) {
            print('Error fetching ujian data: $e');
          }
          
          // If still invalid, use a default value or return false
          if (idTipeUjian <= 0) {
            print('ERROR: Could not determine valid idTipeUjian, using default value 1');
            idTipeUjian = 1; // Use a default value as last resort
          }
        }
        
        // Create request body with validated parameters
        final Map<String, dynamic> requestBody = {
          'nilai': nilai,
          'id_tipe_ujian': idTipeUjian,
          'id_siswa': idSiswa,
          'id_ujian': idUjian,
        };
        
        print('Submitting score with data: $requestBody');
        
        final response = await http.post(
          Uri.parse('$baseUrl/tipe-nilai'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );

        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');
        
        if (response.statusCode == 201 || response.statusCode == 200) {
          print('Score submitted successfully');
          return true;
        } else {
          print('Failed to submit score: ${response.statusCode}');
          print('Response Body: ${response.body}');
          
          // Try to parse error message from response
          try {
            final errorData = jsonDecode(response.body);
            print('Error details: ${errorData['message'] ?? errorData}');
          } catch (e) {
            // Ignore JSON parsing errors
          }
          
          return false;
        }
      } catch (e) {
        print('Error submitting score: $e');
        return false;
      }
    }

    Future<bool> autoSubmitQuizAnswers({
      required String idUjian,
      required List<Map<String, dynamic>> questions,
      required List<String?> selectedAnswers,
    }) async {
      try {
        print('Auto-submitting answers due to timeout');
        
        // Use the existing submitQuizAnswers method
        bool success = await submitQuizAnswers(
          idUjian: idUjian,
          questions: questions,
          selectedAnswers: selectedAnswers,
        );
        
        if (success) {
          print('Auto-submission successful');
          
          // Get current user ID
          final userId = await getCurrentUserId();
          final int siswaId = userId ?? 1;  // Fallback for testing
          
          // Calculate the total score
          double totalScore = await getTotalNilaiSiswa(idUjian, siswaId.toString());
          
          // Submit the score to 'tipe_nilai' table
          int idTipeUjian = 1; // Default value, should be fetched from the server
          
          // Try to fetch the correct idTipeUjian from the ujian data
          try {
            final ujianResponse = await http.get(
              Uri.parse('$baseUrl/ujian/$idUjian'),
            );
            
            if (ujianResponse.statusCode == 200) {
              final ujianData = jsonDecode(ujianResponse.body);
              // Extract tipe_ujian from the response
              if (ujianData['tipe_ujian'] != null) {
                idTipeUjian = ujianData['tipe_ujian'];
              }
            }
          } catch (e) {
            print('Error fetching ujian data: $e');
          }
          
          bool scoreSubmitted = await submitNilaiToTipeNilai(
            totalScore,
            idTipeUjian,
            siswaId,
            int.parse(idUjian),
          );
          
          if (scoreSubmitted) {
            print('Score auto-submitted successfully');
          } else {
            print('Failed to auto-submit score');
          }
          
          return true;
        } else {
          print('Auto-submission failed');
          return false;
        }
      } catch (e) {
        print('Error in auto-submission: $e');
        return false;
      }
    }

    // Method to submit quiz answers and then submit the score
    Future<void> submitQuizAnswersAndScore({
      required String idUjian,
      required List<Map<String, dynamic>> questions,
      required List<String?> selectedAnswers,
      required int idSiswa,  // Update to `int` for `idSiswa`
    }) async {
      try {
        // Step 1: Fetch total score for the student
        double totalScore = await getTotalNilaiSiswa(idUjian, idSiswa.toString()); // Ensure it's a String in the API call

        // Step 2: Submit the score to 'tipe_nilai'
        int idTipeUjian = 1; // Example ID for the exam type (You can fetch this dynamically)
        
        bool scoreSubmitted = await submitNilaiToTipeNilai(
          totalScore,
          idTipeUjian,
          idSiswa,
          int.parse(idUjian),  // Convert `idUjian` to int, if necessary
        );

        if (scoreSubmitted) {
          print('Score submitted successfully');
        } else {
          print('Failed to submit score');
          // Handle error, maybe show a message to the user
        }
      } catch (e) {
        print('Error submitting quiz answers and score: $e');
        // Handle error, maybe show a message to the user
      }
    }

    // Create multiple jawaban siswa at once
    Future<bool> createBatchJawabanSiswa(List<JawabanSiswa> jawabanList) async {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/jawaban-siswa/batch'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'jawaban_list': jawabanList.map((jawaban) => jawaban.toJson()).toList(),
          }),
        );

        if (response.statusCode == 201) {
          print('Batch jawaban siswa created successfully');
          return true;
        } else {
          print('Failed to create batch jawaban siswa: ${response.body}');
          return false;
        }
      } catch (e) {
        print('Error creating batch jawaban siswa: $e');
        return false;
      }
    }

    // Get jawaban siswa by ID
    Future<Map<String, dynamic>?> getJawabanSiswaById(int id) async {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/jawaban-siswa/$id'),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['data'];
        } else {
          print('Failed to get jawaban siswa: ${response.body}');
          return null;
        }
      } catch (e) {
        print('Error getting jawaban siswa: $e');
        return null;
      }
    }

    // Get all jawaban siswa by siswa ID
    Future<List<Map<String, dynamic>>?> getJawabanSiswaBySiswaId(int siswaId) async {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/jawaban-siswa/siswa/$siswaId'),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          print('Failed to get jawaban siswa by siswa ID: ${response.body}');
          return null;
        }
      } catch (e) {
        print('Error getting jawaban siswa by siswa ID: $e');
        return null;
      }
    }

    // Get all jawaban siswa by ujian ID
    Future<List<Map<String, dynamic>>?> getJawabanSiswaByUjianId(int ujianId) async {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/jawaban-siswa/ujian/$ujianId'),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          print('Failed to get jawaban siswa by ujian ID: ${response.body}');
          return null;
        }
      } catch (e) {
        print('Error getting jawaban siswa by ujian ID: $e');
        return null;
      }
    }

    // Helper method to get the current user ID from SharedPreferences
    Future<int?> getCurrentUserId() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        // Try different keys that might store the user ID
        int? userId = prefs.getInt('user_id');
        if (userId == null) {
          userId = prefs.getInt('id_siswa');
        }
        if (userId == null) {
          userId = prefs.getInt('siswa_id');
        }
        if (userId == null) {
          // Try to get it as a string and convert to int
          String? userIdStr = prefs.getString('user_id');
          if (userIdStr != null) {
            userId = int.tryParse(userIdStr);
          }
        }
        
        // If still null, check if we have a user object stored as JSON
        if (userId == null) {
          String? userJson = prefs.getString('user');
          if (userJson != null) {
            try {
              Map<String, dynamic> userData = jsonDecode(userJson);
              userId = userData['id'] ?? userData['id_siswa'] ?? userData['siswa_id'];
            } catch (e) {
              print('Error parsing user JSON: $e');
            }
          }
        }
        
        return userId;
      } catch (e) {
        print('Error getting current user ID: $e');
        return null;
      }
    }

    // Submit quiz answers
    // Helper method for handling answers
    Future<bool> submitQuizAnswers({
      required String idUjian, // Changed from int to String
      required List<Map<String, dynamic>> questions,
      required List<String?> selectedAnswers,
    }) async {
    try {
      // Get current user ID
      final userId = await getCurrentUserId();
      final int siswaId = userId ?? 1;  // Fallback for testing

      if (userId == null) {
        print('User ID not found, using fallback ID: $siswaId');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', siswaId);
      }

      // IMPORTANT: First check if the student has already taken this quiz
      final hasAttempted = await hasStudentTakenQuiz(idUjian, siswaId);
      if (hasAttempted) {
        print('Student has already taken this quiz. Preventing duplicate submission.');
        return false; // Prevent duplicate submission
      }

      // Prepare a list of JawabanSiswa objects
      List<JawabanSiswa> jawabanList = [];

      for (int i = 0; i < questions.length; i++) {
        // Skip if no answer is selected
        if (selectedAnswers[i] == null) continue;

        final question = questions[i];
        final selectedAnswer = selectedAnswers[i]!;

        // Safe parsing of question ID
        int idSoal;
        try {
          idSoal = int.parse(question['id'] ?? '0');
        } catch (e) {
          print('Error parsing question ID: ${question['id']}');
          idSoal = 0;
        }

        // Extract idJawabanSoal for Multiple Choice
        int? idJawabanSoal;
        if (question['id_tipe_soal'] == 1) { // Multiple Choice
          final jawabanListData = question['jawaban_list'] as List<dynamic>? ?? [];
          for (var jawaban in jawabanListData) {
            final teksJawaban = jawaban['teks_jawaban']?.toString() ?? 
                              jawaban['jawaban']?.toString() ?? 
                              jawaban['text']?.toString();
            if (teksJawaban == selectedAnswer) {
              idJawabanSoal = jawaban['id_jawaban_soal'] ?? jawaban['id'];
              break;
            }
          }
        } else if (question['id_tipe_soal'] == 2) { // True/False
          final jawabanListData = question['jawaban_list'] as List<dynamic>? ?? [];
          // Here, we dynamically fetch idJawabanSoal for True/False
          for (var jawaban in jawabanListData) {
            if (jawaban['jawaban'] == selectedAnswer) {
              idJawabanSoal = jawaban['id_jawaban_soal']; // Or the correct ID field
              break;
            }
          }
        }

        jawabanList.add(JawabanSiswa(
          jawabanSiswa: selectedAnswer,
          idSoal: idSoal,
          idSiswa: siswaId,
          idJawabanSoal: idJawabanSoal,
        ));
      }

      // If no answers are available
      if (jawabanList.isEmpty) {
        print('No answers to submit');
        return false;
      }

      // Print data being submitted for debugging
      print('Submitting ${jawabanList.length} answers for user ID: $siswaId');
      for (var jawaban in jawabanList) {
        print('Answer: ${jawaban.toJson()}');
      }

      // Send the answers to the server
      return await createBatchJawabanSiswa(jawabanList);
    } catch (e) {
      print('Error submitting quiz answers: $e');
      return false;
    }
  }
  }
