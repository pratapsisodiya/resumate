class PersonalInfo {
  final String fullName;
  final String? title;
  final String email;
  final String? phone;
  final String? location;
  final String? linkedIn;
  final String? github;
  final String? portfolio;
  final String? bio;

  const PersonalInfo({
    required this.fullName,
    this.title,
    required this.email,
    this.phone,
    this.location,
    this.linkedIn,
    this.github,
    this.portfolio,
    this.bio,
  });

  PersonalInfo copyWith({
    String? fullName,
    String? title,
    String? email,
    String? phone,
    String? location,
    String? linkedIn,
    String? github,
    String? portfolio,
    String? bio,
  }) =>
      PersonalInfo(
        fullName: fullName ?? this.fullName,
        title: title ?? this.title,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        location: location ?? this.location,
        linkedIn: linkedIn ?? this.linkedIn,
        github: github ?? this.github,
        portfolio: portfolio ?? this.portfolio,
        bio: bio ?? this.bio,
      );

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'title': title,
        'email': email,
        'phone': phone,
        'location': location,
        'linkedIn': linkedIn,
        'github': github,
        'portfolio': portfolio,
        'bio': bio,
      };

  factory PersonalInfo.fromJson(Map<String, dynamic> j) => PersonalInfo(
        fullName: j['fullName'] as String? ?? '',
        title: j['title'] as String?,
        email: j['email'] as String? ?? '',
        phone: j['phone'] as String?,
        location: j['location'] as String?,
        linkedIn: j['linkedIn'] as String?,
        github: j['github'] as String?,
        portfolio: j['portfolio'] as String?,
        bio: j['bio'] as String?,
      );
}

class Experience {
  final String company;
  final String role;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final String description;
  final List<String> achievements;
  final List<String> technologies;

  const Experience({
    required this.company,
    required this.role,
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
    required this.description,
    this.achievements = const [],
    this.technologies = const [],
  });

  Map<String, dynamic> toJson() => {
        'company': company,
        'role': role,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'isCurrent': isCurrent,
        'description': description,
        'achievements': achievements,
        'technologies': technologies,
      };

  factory Experience.fromJson(Map<String, dynamic> j) => Experience(
        company: j['company'] as String? ?? '',
        role: j['role'] as String? ?? '',
        startDate: DateTime.tryParse(j['startDate'] as String? ?? '') ?? DateTime.now(),
        endDate: j['endDate'] != null ? DateTime.tryParse(j['endDate'] as String) : null,
        isCurrent: j['isCurrent'] as bool? ?? false,
        description: j['description'] as String? ?? '',
        achievements: List<String>.from(j['achievements'] as List? ?? []),
        technologies: List<String>.from(j['technologies'] as List? ?? []),
      );
}

class Education {
  final String institution;
  final String degree;
  final String? field;
  final DateTime startDate;
  final DateTime? endDate;
  final String? grade;

  const Education({
    required this.institution,
    required this.degree,
    this.field,
    required this.startDate,
    this.endDate,
    this.grade,
  });

  Map<String, dynamic> toJson() => {
        'institution': institution,
        'degree': degree,
        'field': field,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'grade': grade,
      };

  factory Education.fromJson(Map<String, dynamic> j) => Education(
        institution: j['institution'] as String? ?? '',
        degree: j['degree'] as String? ?? '',
        field: j['field'] as String?,
        startDate: DateTime.tryParse(j['startDate'] as String? ?? '') ?? DateTime.now(),
        endDate: j['endDate'] != null ? DateTime.tryParse(j['endDate'] as String) : null,
        grade: j['grade'] as String?,
      );
}

class Skill {
  final String name;
  final String? level;
  final String? category;

  const Skill({required this.name, this.level, this.category});

  Map<String, dynamic> toJson() => {'name': name, 'level': level, 'category': category};

  factory Skill.fromJson(Map<String, dynamic> j) => Skill(
        name: j['name'] as String? ?? '',
        level: j['level'] as String?,
        category: j['category'] as String?,
      );
}

class Project {
  final String name;
  final String description;
  final String? url;
  final String? githubUrl;
  final List<String> technologies;

  const Project({
    required this.name,
    required this.description,
    this.url,
    this.githubUrl,
    this.technologies = const [],
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'url': url,
        'githubUrl': githubUrl,
        'technologies': technologies,
      };

  factory Project.fromJson(Map<String, dynamic> j) => Project(
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
        url: j['url'] as String?,
        githubUrl: j['githubUrl'] as String?,
        technologies: List<String>.from(j['technologies'] as List? ?? []),
      );
}

class Certification {
  final String name;
  final String issuer;
  final DateTime? issueDate;

  const Certification({required this.name, required this.issuer, this.issueDate});

  Map<String, dynamic> toJson() => {
        'name': name,
        'issuer': issuer,
        'issueDate': issueDate?.toIso8601String(),
      };

  factory Certification.fromJson(Map<String, dynamic> j) => Certification(
        name: j['name'] as String? ?? '',
        issuer: j['issuer'] as String? ?? '',
        issueDate: j['issueDate'] != null ? DateTime.tryParse(j['issueDate'] as String) : null,
      );
}

class Resume {
  final String id;
  final PersonalInfo personalInfo;
  final List<Experience> experiences;
  final List<Education> education;
  final List<Skill> skills;
  final List<Project> projects;
  final List<Certification> certifications;
  final String? rawText;
  final DateTime lastUpdated;

  const Resume({
    required this.id,
    required this.personalInfo,
    this.experiences = const [],
    this.education = const [],
    this.skills = const [],
    this.projects = const [],
    this.certifications = const [],
    this.rawText,
    required this.lastUpdated,
  });

  Resume copyWith({
    PersonalInfo? personalInfo,
    List<Experience>? experiences,
    List<Education>? education,
    List<Skill>? skills,
    List<Project>? projects,
    List<Certification>? certifications,
    String? rawText,
  }) =>
      Resume(
        id: id,
        personalInfo: personalInfo ?? this.personalInfo,
        experiences: experiences ?? this.experiences,
        education: education ?? this.education,
        skills: skills ?? this.skills,
        projects: projects ?? this.projects,
        certifications: certifications ?? this.certifications,
        rawText: rawText ?? this.rawText,
        lastUpdated: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'personalInfo': personalInfo.toJson(),
        'experiences': experiences.map((e) => e.toJson()).toList(),
        'education': education.map((e) => e.toJson()).toList(),
        'skills': skills.map((s) => s.toJson()).toList(),
        'projects': projects.map((p) => p.toJson()).toList(),
        'certifications': certifications.map((c) => c.toJson()).toList(),
        'rawText': rawText,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory Resume.fromJson(Map<String, dynamic> j) => Resume(
        id: j['id'] as String? ?? '',
        personalInfo: PersonalInfo.fromJson(j['personalInfo'] as Map<String, dynamic>? ?? {}),
        experiences: (j['experiences'] as List? ?? [])
            .map((e) => Experience.fromJson(e as Map<String, dynamic>))
            .toList(),
        education: (j['education'] as List? ?? [])
            .map((e) => Education.fromJson(e as Map<String, dynamic>))
            .toList(),
        skills: (j['skills'] as List? ?? [])
            .map((e) => Skill.fromJson(e as Map<String, dynamic>))
            .toList(),
        projects: (j['projects'] as List? ?? [])
            .map((e) => Project.fromJson(e as Map<String, dynamic>))
            .toList(),
        certifications: (j['certifications'] as List? ?? [])
            .map((e) => Certification.fromJson(e as Map<String, dynamic>))
            .toList(),
        rawText: j['rawText'] as String?,
        lastUpdated: DateTime.tryParse(j['lastUpdated'] as String? ?? '') ?? DateTime.now(),
      );
}
