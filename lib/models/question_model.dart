import 'package:flutter/material.dart';

enum QuestionType {
  multipleChoice,
  trueFalse,
  shortAnswer,
  matching
}

class Question {
  final String id;
  final String text;
  final QuestionType type;
  final List<Option> options;
  final String correctAnswer;
  final String explanation;
  final String? imageUrl;

  Question({
    required this.id,
    required this.text,
    required this.type,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.imageUrl,
  });
}

class Option {
  final String id;
  final String text;

  Option({required this.id, required this.text});
}

class QuestionRepository {
  // Singleton pattern
  static final QuestionRepository _instance = QuestionRepository._internal();
  factory QuestionRepository() => _instance;
  QuestionRepository._internal();

  // Map of questions by subject and grade
  final Map<String, Map<int, List<Question>>> _questionsBySubjectAndGrade = {
    'Ilmu Pengetahuan Alam': {
      7: _getIpaQuestionsGrade7(),
      8: _getIpaQuestionsGrade8(),
      9: _getIpaQuestionsGrade9(),
    },
    'Matematika': {
      7: _getMathQuestionsGrade7(),
      8: _getMathQuestionsGrade8(),
      9: _getMathQuestionsGrade9(),
    },
    'Bahasa Indonesia': {
      7: _getBahasaQuestionsGrade7(),
      8: _getBahasaQuestionsGrade8(),
      9: _getBahasaQuestionsGrade9(),
    },
    'Ilmu Pengetahuan Sosial': {
      7: _getIpsQuestionsGrade7(),
      8: _getIpsQuestionsGrade8(),
      9: _getIpsQuestionsGrade9(),
    },
    'Bahasa Inggris': {
      7: _getEnglishQuestionsGrade7(),
      8: _getEnglishQuestionsGrade8(),
      9: _getEnglishQuestionsGrade9(),
    },
    'Seni Budaya': {
      7: _getArtQuestionsGrade7(),
      8: _getArtQuestionsGrade8(),
      9: _getArtQuestionsGrade9(),
    },
  };

  // Get questions for a specific subject and grade
  List<Question> getQuestionsForSubjectAndGrade(String subject, int grade) {
    if (_questionsBySubjectAndGrade.containsKey(subject) &&
        _questionsBySubjectAndGrade[subject]!.containsKey(grade)) {
      return _questionsBySubjectAndGrade[subject]![grade]!;
    }
    return [];
  }

  // Sample question generators for each subject and grade
  static List<Question> _getIpaQuestionsGrade7() {
    return [
      Question(
        id: 'ipa7_1',
        text: 'Apa yang dimaksud dengan fotosintesis?',
        type: QuestionType.multipleChoice,
        options: [
          Option(id: 'A', text: 'Proses pembuatan makanan pada tumbuhan dengan bantuan cahaya matahari'),
          Option(id: 'B', text: 'Proses pernapasan pada tumbuhan'),
          Option(id: 'C', text: 'Proses perkembangbiakan tumbuhan'),
          Option(id: 'D', text: 'Proses penguapan air pada tumbuhan'),
        ],
        correctAnswer: 'A',
        explanation: 'Fotosintesis adalah proses pembuatan makanan pada tumbuhan dengan bantuan cahaya matahari, air, dan karbon dioksida untuk menghasilkan glukosa dan oksigen.',
      ),
      Question(
        id: 'ipa7_2',
        text: 'Manakah dari berikut ini yang merupakan contoh perubahan fisika?',
        type: QuestionType.multipleChoice,
        options: [
          Option(id: 'A', text: 'Pembakaran kertas'),
          Option(id: 'B', text: 'Perkaratan besi'),
          Option(id: 'C', text: 'Mencairnya es'),
          Option(id: 'D', text: 'Fermentasi tape'),
        ],
        correctAnswer: 'C',
        explanation: 'Mencairnya es adalah perubahan fisika karena hanya mengubah bentuk (dari padat ke cair) tanpa mengubah sifat kimianya.',
      ),
      Question(
        id: 'ipa7_3',
        text: 'Apakah pernyataan berikut benar: "Semua makhluk hidup terdiri dari sel"?',
        type: QuestionType.trueFalse,
        options: [
          Option(id: 'A', text: 'Benar'),
          Option(id: 'B', text: 'Salah'),
        ],
        correctAnswer: 'A',
        explanation: 'Benar, semua makhluk hidup terdiri dari sel, baik organisme uniseluler maupun multiseluler.',
      ),
    ];
  }

  static List<Question> _getIpaQuestionsGrade8() {
    return [
      Question(
        id: 'ipa8_1',
        text: 'Apa fungsi utama sistem pencernaan manusia?',
        type: QuestionType.multipleChoice,
        options: [
          Option(id: 'A', text: 'Mengangkut oksigen ke seluruh tubuh'),
          Option(id: 'B', text: 'Memecah makanan menjadi nutrisi yang dapat diserap tubuh'),
          Option(id: 'C', text: 'Mengeluarkan karbon dioksida dari tubuh'),
          Option(id: 'D', text: 'Mengatur suhu tubuh'),
        ],
        correctAnswer: 'B',
        explanation: 'Fungsi utama sistem pencernaan adalah memecah makanan menjadi nutrisi yang dapat diserap dan digunakan oleh tubuh.',
      ),
      Question(
        id: 'ipa8_2',
        text: 'Manakah dari berikut ini yang merupakan sumber energi terbarukan?',
        type: QuestionType.multipleChoice,
        options: [
          Option(id: 'A', text: 'Batu bara'),
          Option(id: 'B', text: 'Minyak bumi'),
          Option(id: 'C', text: 'Energi matahari'),
          Option(id: 'D', text: 'Gas alam'),
        ],
        correctAnswer: 'C',
        explanation: 'Energi matahari adalah sumber energi terbarukan karena tidak akan habis dan dapat dimanfaatkan terus-menerus.',
      ),
    ];
  }

  static List<Question> _getIpaQuestionsGrade9() {
    return [
      Question(
        id: 'ipa9_1',
        text: 'Apa yang dimaksud dengan hukum Newton kedua?',
        type: QuestionType.multipleChoice,
        options: [
          Option(id: 'A', text: 'Setiap aksi akan menimbulkan reaksi yang sama besar dan berlawanan arah'),
          Option(id: 'B', text: 'Benda akan tetap diam atau bergerak lurus beraturan jika tidak ada gaya yang bekerja padanya'),
          Option(id: 'C', text: 'Percepatan benda berbanding lurus dengan gaya yang bekerja dan berbanding terbalik dengan massanya'),
          Option(id: 'D', text: 'Energi tidak dapat diciptakan atau dimusnahkan, hanya dapat diubah bentuknya'),
        ],
        correctAnswer: 'C',
        explanation: 'Hukum Newton kedua menyatakan bahwa percepatan benda berbanding lurus dengan gaya yang bekerja dan berbanding terbalik dengan massanya (F = m × a).',
      ),
      Question(
        id: 'ipa9_2',
        text: 'Apa yang terjadi pada atom ketika mengalami ionisasi?',
        type: QuestionType.multipleChoice,
        options: [
          Option(id: 'A', text: 'Atom kehilangan atau mendapatkan elektron'),
          Option(id: 'B', text: 'Atom kehilangan atau mendapatkan proton'),
          Option(id: 'C', text: 'Atom kehilangan atau mendapatkan neutron'),
          Option(id: 'D', text: 'Atom berubah menjadi unsur lain'),
        ],
        correctAnswer: 'A',
        explanation: 'Ionisasi adalah proses di mana atom kehilangan atau mendapatkan elektron, sehingga menjadi bermuatan (ion).',
      ),
    ];
  }

  // Placeholder methods for other subjects
  static List<Question> _getMathQuestionsGrade7() {
    return [
      Question(
        id: 'math7_1',
        text: 'Berapakah hasil dari 3x + 5 = 20?',
        type: QuestionType.multipleChoice,
        options: [
          Option(id: 'A', text: 'x = 3'),
          Option(id: 'B', text: 'x = 5'),
          Option(id: 'C', text: 'x = 7'),
          Option(id: 'D', text: 'x = 15'),
        ],
        correctAnswer: 'B',
        explanation: '3x + 5 = 20\n3x = 20 - 5\n3x = 15\nx = 5',
      ),
    ];
  }

  static List<Question> _getMathQuestionsGrade8() {
    return [
      Question(
        id: 'math8_1',
        text: 'Jika a² + b² = 25 dan a + b = 7, berapakah nilai a × b?',
        type: QuestionType.multipleChoice,
        options: [
          Option(id: 'A', text: '10'),
          Option(id: 'B', text: '12'),
          Option(id: 'C', text: '15'),
          Option(id: 'D', text: '24'),
        ],
        correctAnswer: 'B',
        explanation: '(a + b)² = a² + 2ab + b²\n7² = 25 + 2ab\n49 = 25 + 2ab\n2ab = 24\nab = 12',
      ),
    ];
  }

  static List<Question> _getMathQuestionsGrade9() {
    return [
      Question(
        id: 'math9_1',
        text: 'Berapakah luas permukaan kubus dengan panjang rusuk 5 cm?',
        type: QuestionType.multipleChoice,
        options: [
          Option(id: 'A', text: '25 cm²'),
          Option(id: 'B', text: '125 cm²'),
          Option(id: 'C', text: '150 cm²'),
          Option(id: 'D', text: '175 cm²'),
        ],
        correctAnswer: 'C',
        explanation: 'Luas permukaan kubus = 6 × s²\nLuas permukaan kubus = 6 × 5² = 6 × 25 = 150 cm²',
      ),
    ];
  }

  static List<Question> _getBahasaQuestionsGrade7() {
    return [
      Question(
        id: 'bahasa7_1',
        text: 'Manakah yang merupakan contoh kalimat aktif?',
        type: QuestionType.multipleChoice,
        options: [
          Option(id: 'A', text: 'Buku itu dibaca oleh Ani'),
          Option(id: 'B', text: 'Ani membaca buku itu'),
          Option(id: 'C', text: 'Terdengar suara gemuruh dari kejauhan'),
          Option(id: 'D', text: 'Pintu itu terbuka dengan sendirinya'),
        ],
        correctAnswer: 'B',
        explanation: 'Kalimat aktif adalah kalimat yang subjeknya melakukan pekerjaan/tindakan. Pada kalimat "Ani membaca buku itu", Ani (subjek) melakukan tindakan membaca.',
      ),
    ];
  }

  static List<Question> _getBahasaQuestionsGrade8() {
    return [
      Question(
        id: 'bahasa8_1',
        text: 'Apakah pengertian dari majas personifikasi?',
        type: QuestionType.multipleChoice,
        options: [
          Option(id: 'A', text: 'Membandingkan dua hal secara langsung'),
          Option(id: 'B', text: 'Melebih-lebihkan sesuatu'),
          Option(id: 'C', text: 'Menggambarkan benda mati seolah-olah hidup'),
          Option(id: 'D', text: 'Menggunakan kata yang berlawanan arti'),
        ],
        correctAnswer: 'C',
        explanation: 'Majas personifikasi adalah majas yang menggambarkan benda mati seolah-olah memiliki sifat seperti manusia atau makhluk hidup.',
      ),
    ];
  }

  static List<Question> _getBahasaQuestionsGrade9() {
    return [
      Question(
        id: 'bahasa9_1',
        text: 'Manakah yang merupakan contoh pantun?',
        type: QuestionType.multipleChoice,
        options: [
          Option(id: 'A', text: 'Bermain layang-layang di tepi pantai, Angin bertiup membawa kesejukan'),
          Option(id: 'B', text: 'Berakit-rakit ke hulu, berenang-renang ke tepian. Bersakit-sakit dahulu, bersenang-senang kemudian'),
          Option(id: 'C', text: 'Aku ini binatang jalang, Dari kumpulannya terbuang'),
          Option(id: 'D', text: 'Meski langit runtuh, kebenaran harus tetap ditegakkan'),
        ],
        correctAnswer: 'B',
        explanation: 'Pantun memiliki ciri-ciri: terdiri dari 4 baris, bersajak a-b-a-b, dan memiliki sampiran (baris 1-2) serta isi (baris 3-4).',
      ),
    ];
  }

  static List<Question> _getIpsQuestionsGrade7() {
    return [
      Question(
        id: 'ips7_1',
        text: 'Apa yang dimaksud dengan interaksi sosial?',
        type: QuestionType.multipleChoice,
        options: [
          Option(id: 'A', text: 'Hubungan timbal balik antara individu dengan individu, individu dengan kelompok, atau kelompok dengan kelompok'),
          Option(id: 'B', text: 'Kegiatan ekonomi yang dilakukan masyarakat'),
          Option(id: 'C', text: 'Proses pembentukan kepribadian seseorang'),
          Option(id: 'D', text: 'Cara manusia beradaptasi dengan lingkungannya'),
        ],
        correctAnswer: 'A',
        explanation: 'Interaksi sosial adalah hubungan timbal balik antara individu dengan individu, individu dengan kelompok, atau kelompok dengan kelompok yang saling mempengaruhi.',
      ),
    ];
  }

  static List<Question> _getIpsQuestionsGrade8() {
    return [
      Question(
        id: 'ips8_1',
        text: 'Kapan Proklamasi Kemerdekaan Indonesia dilaksanakan?',
        type: QuestionType.multipleChoice,
        options: [
          Option(id: 'A', text: '17 Agustus 1945'),
          Option(id: 'B', text: '1 Juni 1945'),
          Option(id: 'C', text: '28 Oktober 1928'),
          Option(id: 'D', text: '21 April 1945'),
        ],
        correctAnswer: 'A',
        explanation: 'Proklamasi Kemerdekaan Indonesia dilaksanakan pada tanggal 17 Agustus 1945 oleh Ir. Soekarno dan Drs. Mohammad Hatta.',
      ),
    ];
  }

  static List<Question> _getIpsQuestionsGrade9() {
    return [
      Question(
        id: 'ips9_1',
        text: 'Apa yang dimaksud dengan globalisasi?',
        type: QuestionType.multipleChoice,
        options: [
          Option(id: 'A', text: 'Proses penyebaran budaya lokal ke seluruh dunia'),
          Option(id: 'B', text: 'Proses integrasi internasional yang terjadi karena pertukaran pandangan dunia, produk, pemikiran, dan aspek-aspek kebudayaan lainnya'),
          Option(id: 'C', text: 'Proses pembentukan negara-negara baru'),
          Option(id: 'D', text: 'Proses penguasaan suatu negara oleh negara lain'),
        ],
        correctAnswer: 'B',
        explanation: 'Globalisasi adalah proses integrasi internasional yang terjadi karena pertukaran pandangan dunia, produk, pemikiran, dan aspek-aspek kebudayaan lainnya.',
      ),
    ];
  }

  static List<Question> _getEnglishQuestionsGrade7() {
    return [
      Question(
        id: 'eng7_1',
        text: 'Which of the following is the correct sentence?',
        type: QuestionType.multipleChoice,
        options: [
          Option(id: 'A', text: 'She go to school every day'),
          Option(id: 'B', text: 'She goes to school every day'),
          Option(id: 'C', text: 'She going to school every day'),
          Option(id: 'D', text: 'She gone to school every day'),
        ],
        correctAnswer: 'B',
        explanation: 'For third person singular (he, she, it) in simple present tense, we add -s or -es to the verb. So "She goes to school every day" is correct.',
      ),
    ];
  }

  static List<Question> _getEnglishQuestionsGrade8() {
    return [
      Question(
        id: 'eng8_1',
        text: 'What is the past tense of "write"?',
        type: QuestionType.multipleChoice,
        options: [
          Option(id: 'A', text: 'Writed'),
          Option(id: 'B', text: 'Wrote'),
          Option(id: 'C', text: 'Written'),
          Option(id: 'D', text: 'Writing'),
        ],
        correctAnswer: 'B',
        explanation: 'The past tense of "write" is "wrote". "Written" is the past participle form.',
      ),
    ];
  }

  static List<Question> _getEnglishQuestionsGrade9() {
    return [
      Question(
        id: 'eng9_1',
        text: 'Choose the correct conditional sentence:',
        type: QuestionType.multipleChoice,
        options: [
          Option(id: 'A', text: 'If it rains tomorrow, I stay at home'),
          Option(id: 'B', text: 'If it rains tomorrow, I stayed at home'),
          Option(id: 'C', text: 'If it rains tomorrow, I will stay at home'),
          Option(id: 'D', text: 'If it will rain tomorrow, I will stay at home'),
        ],
        correctAnswer: 'C',
        explanation: 'For first conditional (possible future condition), we use "if + present simple, will + infinitive". So "If it rains tomorrow, I will stay at home" is correct.',
      ),
    ];
  }

  static List<Question> _getArtQuestionsGrade7() {
    return [
      Question(
        id: 'art7_1',
        text: 'Apa yang dimaksud dengan seni rupa dua dimensi?',
        type: QuestionType.multipleChoice,
        options: [
          Option(id: 'A', text: 'Karya seni yang hanya memiliki panjang dan lebar'),
          Option(id: 'B', text: 'Karya seni yang memiliki panjang, lebar, dan tinggi'),
          Option(id: 'C', text: 'Karya seni yang dapat dinikmati melalui pendengaran'),
          Option(id: 'D', text: 'Karya seni yang menggabungkan berbagai media'),
        ],
        correctAnswer: 'A',
        explanation: 'Seni rupa dua dimensi adalah karya seni yang hanya memiliki panjang dan lebar, seperti lukisan, gambar, dan fotografi.',
      ),
    ];
  }

  static List<Question> _getArtQuestionsGrade8() {
    return [
      Question(
        id: 'art8_1',
        text: 'Alat musik tradisional apakah yang berasal dari Jawa Barat?',
        type: QuestionType.multipleChoice,
        options: [
          Option(id: 'A', text: 'Sasando'),
          Option(id: 'B', text: 'Angklung'),
          Option(id: 'C', text: 'Kolintang'),
          Option(id: 'D', text: 'Tifa'),
        ],
        correctAnswer: 'B',
        explanation: 'Angklung adalah alat musik tradisional yang berasal dari Jawa Barat, terbuat dari bambu yang dibunyikan dengan cara digoyangkan.',
      ),
    ];
  }

  static List<Question> _getArtQuestionsGrade9() {
    return [
      Question(
        id: 'art9_1',
        text: 'Apa yang dimaksud dengan seni kontemporer?',
        type: QuestionType.multipleChoice,
        options: [
          Option(id: 'A', text: 'Seni yang diciptakan pada masa lampau'),
          Option(id: 'B', text: 'Seni yang mengikuti aturan dan tradisi yang ketat'),
          Option(id: 'C', text: 'Seni yang diciptakan pada masa kini dan sering kali mendobrak batasan konvensional'),
          Option(id: 'D', text: 'Seni yang hanya dapat dinikmati oleh kalangan tertentu'),
        ],
        correctAnswer: 'C',
        explanation: 'Seni kontemporer adalah seni yang diciptakan pada masa kini dan sering kali mendobrak batasan konvensional, mencerminkan budaya dan isu-isu kontemporer.',
      ),
    ];
  }
}
