/// Question representation in the interview sequence.
class InterviewQuestion {
  final String id;
  final String? tag;
  final String text;
  final String voice;

  const InterviewQuestion({
    required this.id,
    this.tag,
    required this.text,
    this.voice = 'en-US-GuyNeural',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        if (tag != null) 'tag': tag,
        'text': text,
        'voice': voice,
      };

  factory InterviewQuestion.fromJson(Map<String, dynamic> json) =>
      InterviewQuestion(
        id: json['id'] as String? ?? '',
        tag: json['tag'] as String?,
        text: json['text'] as String? ?? '',
        voice: json['voice'] as String? ?? 'en-US-GuyNeural',
      );
}

/// Candidate metadata for the interview session.
class InterviewCandidate {
  final String name;
  final String email;
  final String role;
  final String difficulty;

  const InterviewCandidate({
    required this.name,
    required this.email,
    this.role = 'Frontend Developer',
    this.difficulty = 'easy',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'role': role,
        'difficulty': difficulty,
      };

  factory InterviewCandidate.fromJson(Map<String, dynamic> json) =>
      InterviewCandidate(
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? 'Frontend Developer',
        difficulty: json['difficulty'] as String? ?? 'easy',
      );
}

/// Single rendered lip-sync question segment with video URL.
class InterviewSegment {
  final int segmentIndex;
  final String questionId;
  final String? tag;
  final String questionText;
  final double durationSeconds;
  final String videoUrl;

  const InterviewSegment({
    required this.segmentIndex,
    required this.questionId,
    this.tag,
    required this.questionText,
    required this.durationSeconds,
    required this.videoUrl,
  });

  Map<String, dynamic> toJson() => {
        'segmentIndex': segmentIndex,
        'questionId': questionId,
        if (tag != null) 'tag': tag,
        'questionText': questionText,
        'durationSeconds': durationSeconds,
        'videoUrl': videoUrl,
      };

  factory InterviewSegment.fromJson(Map<String, dynamic> json) =>
      InterviewSegment(
        segmentIndex: (json['segmentIndex'] as num?)?.toInt() ?? 0,
        questionId: json['questionId'] as String? ?? '',
        tag: json['tag'] as String?,
        questionText: json['questionText'] as String? ?? '',
        durationSeconds:
            (json['durationSeconds'] as num?)?.toDouble() ?? 0.0,
        videoUrl: json['videoUrl'] as String? ?? '',
      );
}

/// Overall Interview Session Document matching Firestore `interviews/{interviewId}`.
class InterviewManifest {
  final String interviewId;
  final String status; // 'pending' | 'processing' | 'ready' | 'completed' | 'error'
  final String? idleLoopVideoUrl;
  final List<InterviewSegment> segments;
  final InterviewCandidate candidate;
  final int totalQuestions;
  final int completedQuestions;
  final String? error;
  final DateTime? createdAt;

  const InterviewManifest({
    required this.interviewId,
    required this.status,
    this.idleLoopVideoUrl,
    this.segments = const [],
    required this.candidate,
    required this.totalQuestions,
    this.completedQuestions = 0,
    this.error,
    this.createdAt,
  });

  factory InterviewManifest.fromJson(Map<String, dynamic> json) {
    List<InterviewSegment> segs = [];
    if (json['segments'] != null && json['segments'] is List) {
      segs = (json['segments'] as List)
          .map((s) => InterviewSegment.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList();
    }

    DateTime? dt;
    if (json['createdAt'] != null) {
      if (json['createdAt'] is String) {
        dt = DateTime.tryParse(json['createdAt'] as String);
      }
    }

    return InterviewManifest(
      interviewId: json['interviewId'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      idleLoopVideoUrl: json['idleLoopVideoUrl'] as String?,
      segments: segs,
      candidate: json['candidate'] != null
          ? InterviewCandidate.fromJson(
              Map<String, dynamic>.from(json['candidate'] as Map))
          : const InterviewCandidate(name: '', email: ''),
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? segs.length,
      completedQuestions:
          (json['completedQuestions'] as num?)?.toInt() ?? 0,
      error: json['error'] as String?,
      createdAt: dt,
    );
  }
}

/// Request payload for POST /v1/interview/generate-sequence
class GenerateInterviewSequenceRequest {
  final String avatarMediaUrl;
  final InterviewCandidate candidate;
  final bool generateIdleLoop;
  final List<InterviewQuestion> questions;

  const GenerateInterviewSequenceRequest({
    required this.avatarMediaUrl,
    required this.candidate,
    this.generateIdleLoop = true,
    required this.questions,
  });

  Map<String, dynamic> toJson() => {
        'avatarMediaUrl': avatarMediaUrl,
        'candidate': candidate.toJson(),
        'generateIdleLoop': generateIdleLoop,
        'questions': questions.map((q) => q.toJson()).toList(),
      };
}

/// Response payload from POST /v1/interview/generate-sequence
class GenerateInterviewSequenceResponse {
  final String interviewId;
  final String status;
  final int totalQuestions;
  final int estimatedCost;

  const GenerateInterviewSequenceResponse({
    required this.interviewId,
    required this.status,
    required this.totalQuestions,
    required this.estimatedCost,
  });

  factory GenerateInterviewSequenceResponse.fromJson(
          Map<String, dynamic> json) =>
      GenerateInterviewSequenceResponse(
        interviewId: json['interviewId'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
        estimatedCost: (json['estimatedCost'] as num?)?.toInt() ?? 50,
      );
}

/// State enum for the interactive interview session.
enum InterviewState {
  loading,
  interviewerSpeaking,
  candidateAnswering,
  completed,
  error,
}

/// Preloaded default configuration for Akash Kumar Solanki's Frontend Interview.
class PreloadedInterviewData {
  static const String defaultActorVideoUrl =
      'https://firebasestorage.googleapis.com/v0/b/ai-studio-637ab.firebasestorage.app/o/interview%2FsampleVideo%2F8048476-hd_1080_1920_25fps%20(1).mp4?alt=media';

  static const InterviewCandidate defaultCandidate = InterviewCandidate(
    name: 'Akash Kumar Solanki',
    email: 'akashsolanki1292001@gmail.com',
    role: 'Frontend Developer',
    difficulty: 'easy',
  );

  static const List<InterviewQuestion> defaultQuestions = [
    InterviewQuestion(
      id: 'Q1',
      tag: 'Introduction',
      text:
          'Hey Akash Kumar Solanki, I’m Aeologic Bot, the interviewer representative from Aeologic Technologies. It’s a pleasure to connect with you today. To begin, I would love to learn more about you. Could you please introduce yourself and share your professional journey so far? I’d also be interested in hearing about the key skills, technical expertise, and industry knowledge you have gained through your experience over the years, along with the projects or achievements you are most proud of.',
      voice: 'en-US-GuyNeural',
    ),
    InterviewQuestion(
      id: 'Q2',
      tag: 'HTML5 Core',
      text:
          'Can you explain what HTML5 is and how it differs from previous versions of HTML?',
      voice: 'en-US-GuyNeural',
    ),
    InterviewQuestion(
      id: 'Q3',
      tag: 'CSS3 Features',
      text:
          'What are some of the new features introduced in CSS3 that you frequently use in modern frontend development?',
      voice: 'en-US-GuyNeural',
    ),
    InterviewQuestion(
      id: 'Q4',
      tag: 'JavaScript Essentials',
      text:
          'What is the role of JavaScript in frontend development and how does it interact with the DOM?',
      voice: 'en-US-GuyNeural',
    ),
    InterviewQuestion(
      id: 'Q5',
      tag: 'React.js Ecosystem',
      text:
          'Why is React.js so popular for building user interfaces, and what are its core architectural concepts?',
      voice: 'en-US-GuyNeural',
    ),
    InterviewQuestion(
      id: 'Q6',
      tag: 'React Components',
      text:
          'How do you create reusable components in React, and what best practices do you follow for state management?',
      voice: 'en-US-GuyNeural',
    ),
    InterviewQuestion(
      id: 'Q7',
      tag: 'Responsive Layouts',
      text:
          'Why is responsive design crucial, and how do you ensure an application looks great across all screen sizes?',
      voice: 'en-US-GuyNeural',
    ),
    InterviewQuestion(
      id: 'Q8',
      tag: 'CSS Frameworks',
      text:
          'How do CSS frameworks like Bootstrap and Tailwind CSS speed up your frontend workflow?',
      voice: 'en-US-GuyNeural',
    ),
    InterviewQuestion(
      id: 'Q9',
      tag: 'REST APIs',
      text:
          'How do you integrate and consume RESTful APIs in a React or frontend application?',
      voice: 'en-US-GuyNeural',
    ),
    InterviewQuestion(
      id: 'Q10',
      tag: 'JSON Data',
      text:
          'What is JSON and why is it the standard data interchange format in modern web applications?',
      voice: 'en-US-GuyNeural',
    ),
    InterviewQuestion(
      id: 'Q11',
      tag: 'Browser Compatibility',
      text:
          'How do you test and handle cross-browser compatibility issues across Chrome, Safari, and Firefox?',
      voice: 'en-US-GuyNeural',
    ),
    InterviewQuestion(
      id: 'Q12',
      tag: 'Testing & Debugging',
      text:
          'What tools and workflows do you use for debugging and testing frontend applications effectively?',
      voice: 'en-US-GuyNeural',
    ),
  ];
}
