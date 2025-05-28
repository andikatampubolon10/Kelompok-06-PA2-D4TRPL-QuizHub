class SubjectData {
  // Singleton pattern for subject data
  static final SubjectData _instance = SubjectData._internal();
  
  factory SubjectData() => _instance;
  
  SubjectData._internal();

  // Map of subjects by grade level
  final Map<int, List<Subject>> subjectsByGrade = {
    7: [
      Subject(name: 'Ilmu Pengetahuan Alam', icon: 'book'),
      Subject(name: 'Matematika', icon: 'book'),
      Subject(name: 'Bahasa Indonesia', icon: 'book'),
      Subject(name: 'Ilmu Pengetahuan Sosial', icon: 'book'),
      Subject(name: 'Bahasa Inggris', icon: 'book'),
      Subject(name: 'Seni Budaya', icon: 'book'),
      Subject(name: 'Pendidikan Jasmani', icon: 'book'),
    ],
    8: [
      Subject(name: 'Ilmu Pengetahuan Alam', icon: 'book'),
      Subject(name: 'Matematika', icon: 'book'),
      Subject(name: 'Bahasa Indonesia', icon: 'book'),
      Subject(name: 'Ilmu Pengetahuan Sosial', icon: 'book'),
      Subject(name: 'Bahasa Inggris', icon: 'book'),
      Subject(name: 'Seni Budaya', icon: 'book'),
      Subject(name: 'Teknologi Informasi', icon: 'book'),
    ],
    9: [
      Subject(name: 'Ilmu Pengetahuan Alam', icon: 'book'),
      Subject(name: 'Matematika', icon: 'book'),
      Subject(name: 'Bahasa Indonesia', icon: 'book'),
      Subject(name: 'Ilmu Pengetahuan Sosial', icon: 'book'),
      Subject(name: 'Bahasa Inggris', icon: 'book'),
      Subject(name: 'Seni Budaya', icon: 'book'),
      Subject(name: 'Prakarya', icon: 'book'),
    ],
  };

  // Get subjects for a specific grade
  List<Subject> getSubjectsForGrade(int grade) {
    return subjectsByGrade[grade] ?? [];
  }

  // Check if grade exists
  bool hasGrade(int grade) {
    return subjectsByGrade.containsKey(grade);
  }

  // Get all available grades
  List<int> getAllGrades() {
    return subjectsByGrade.keys.toList()..sort();
  }
}

class Subject {
  final String name;
  final String icon;

  Subject({required this.name, required this.icon});
}

