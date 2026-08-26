import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/aperture_indicator.dart';
import '../models/interview_models.dart';
import '../widgets/interview_header.dart';
import '../widgets/question_overlay_card.dart';
import 'interview_summary_view.dart';

class InteractiveInterviewView extends StatefulWidget {
  final String interviewId;
  final InterviewCandidate candidate;
  final List<InterviewQuestion>? initialQuestions;

  const InteractiveInterviewView({
    super.key,
    required this.interviewId,
    required this.candidate,
    this.initialQuestions,
  });

  @override
  State<InteractiveInterviewView> createState() =>
      _InteractiveInterviewViewState();
}

class _InteractiveInterviewViewState extends State<InteractiveInterviewView> {
  VideoPlayerController? _currentVideoController;
  VideoPlayerController? _idleLoopController;
  InterviewState _state = InterviewState.loading;

  List<InterviewSegment> _segments = [];
  String? _idleLoopUrl;
  int _currentQuestionIndex = 0;
  int _answerTimerSeconds = 0;
  int _totalSessionElapsedSeconds = 0;
  Timer? _answerTimer;
  Timer? _sessionTimer;
  StreamSubscription? _firestoreSubscription;
  String _loadingStatusText = 'Connecting to AI Interview engine...';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startSessionTimer();
    _listenToInterviewDocument();
  }

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _totalSessionElapsedSeconds++;
    });
  }

  /// Listen to real-time Firestore document updates for interview segments
  void _listenToInterviewDocument() {
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('interviews')
        .doc(widget.interviewId)
        .snapshots()
        .listen((doc) async {
      if (!doc.exists) {
        setState(() {
          _loadingStatusText = 'Waiting for interview session to initialize...';
        });
        return;
      }

      final data = doc.data()!;
      final status = data['status'] as String? ?? 'pending';
      _idleLoopUrl = data['idleLoopVideoUrl'] as String?;

      if (data['segments'] != null && data['segments'] is List) {
        final rawSegments = data['segments'] as List<dynamic>;
        _segments = rawSegments
            .map((s) => InterviewSegment.fromJson(
                Map<String, dynamic>.from(s as Map)))
            .toList();
      }

      if (_state == InterviewState.loading) {
        if (_segments.isNotEmpty) {
          if (_idleLoopUrl != null && _idleLoopController == null) {
            await _initializeIdleController(_idleLoopUrl!);
          }
          await _startQuestion(0);
        } else {
          setState(() {
            _loadingStatusText = status == 'processing'
                ? 'Synthesizing voice & animating interviewer avatar...'
                : 'Preparing Question 1 video stream...';
          });
        }
      } else if (status == 'error') {
        setState(() {
          _state = InterviewState.error;
          _errorMessage = data['error'] as String? ?? 'An error occurred during interview generation.';
        });
      }
    }, onError: (e) {
      Logger.e('Firestore stream error: $e');
      setState(() {
        _state = InterviewState.error;
        _errorMessage = 'Connection error: ${e.toString()}';
      });
    });
  }

  /// Initializes the silent breathing idle loop controller
  Future<void> _initializeIdleController(String url) async {
    try {
      await _idleLoopController?.dispose();
      _idleLoopController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _idleLoopController!.initialize();
      await _idleLoopController!.setLooping(true);
      await _idleLoopController!.setVolume(0.0); // Silent breathing loop
    } catch (e) {
      Logger.w('Failed to initialize idle loop controller: $e');
    }
  }

  /// Starts playing a specific question segment
  Future<void> _startQuestion(int index) async {
    if (index >= _segments.length) {
      _completeInterview();
      return;
    }

    _stopAnswerTimer();
    final segment = _segments[index];

    setState(() {
      _currentQuestionIndex = index;
      _state = InterviewState.interviewerSpeaking;
    });

    try {
      await _idleLoopController?.pause();
      await _currentVideoController?.dispose();
      _currentVideoController =
          VideoPlayerController.networkUrl(Uri.parse(segment.videoUrl));
      await _currentVideoController!.initialize();
      await _currentVideoController!.play();

      // Listen for video duration completion to automatically switch to candidate
      _currentVideoController!.addListener(_videoPlayerListener);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      Logger.e('Error playing question video segment: $e');
      // If question video failed to stream, allow candidate to answer based on text
      _switchToCandidateTurn();
    }
  }

  void _videoPlayerListener() {
    if (_currentVideoController == null) return;
    final value = _currentVideoController!.value;
    if (value.isInitialized &&
        value.position >= value.duration &&
        _state == InterviewState.interviewerSpeaking) {
      _switchToCandidateTurn();
    }
  }

  /// Transitions to candidate answering mode + seamless idle video loop
  void _switchToCandidateTurn() {
    _currentVideoController?.removeListener(_videoPlayerListener);
    _currentVideoController?.pause();

    setState(() {
      _state = InterviewState.candidateAnswering;
      _answerTimerSeconds = 0;
    });

    // Loop idle breathing video
    _idleLoopController?.seekTo(Duration.zero);
    _idleLoopController?.play();

    // Start answer duration timer
    _answerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _answerTimerSeconds++;
        });
      }
    });
  }

  void _stopAnswerTimer() {
    _answerTimer?.cancel();
    _answerTimer = null;
  }

  /// Advances to next question segment
  void _onNextQuestionPressed() async {
    await HapticFeedback.selectionClick();
    await _idleLoopController?.pause();
    await _startQuestion(_currentQuestionIndex + 1);
  }

  void _completeInterview() {
    _stopAnswerTimer();
    _sessionTimer?.cancel();

    Get.off(() => InterviewSummaryView(
          candidate: widget.candidate,
          completedQuestions: _segments.length,
          totalQuestions: widget.initialQuestions?.length ?? _segments.length,
          totalDurationSeconds: _totalSessionElapsedSeconds,
        ));
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        title: Text(
          'Exit Interview?',
          style: AppTextStyles.headingSmall(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to exit? Your progress in this interview will not be saved.',
          style: AppTextStyles.bodyMedium(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Stay',
              style: AppTextStyles.labelMedium(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Exit',
              style: AppTextStyles.labelMedium(color: AppColors.statusError),
            ),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    _stopAnswerTimer();
    _sessionTimer?.cancel();
    _currentVideoController?.removeListener(_videoPlayerListener);
    _currentVideoController?.dispose();
    _idleLoopController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSegment = _segments.isNotEmpty &&
            _currentQuestionIndex < _segments.length
        ? _segments[_currentQuestionIndex]
        : null;

    final totalQuestions = widget.initialQuestions?.length ??
        (_segments.isNotEmpty ? _segments.length : 12);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgApp,
        body: SafeArea(
          child: _state == InterviewState.loading
              ? _buildLoadingView()
              : _state == InterviewState.error
                  ? _buildErrorView()
                  : Stack(
                      children: [
                        // 1. Full Viewport Video Area (Interviewer / Idle Breathing Loop)
                        Center(
                          child: AspectRatio(
                            aspectRatio: _currentVideoController != null &&
                                    _currentVideoController!.value.isInitialized
                                ? _currentVideoController!.value.aspectRatio
                                : 9 / 16,
                            child: _buildVideoViewport(),
                          ),
                        ),

                        // 2. Top Header with Progress, Question Counter & Exit
                        Positioned(
                          top: 16.h,
                          left: 16.w,
                          right: 16.w,
                          child: InterviewHeader(
                            currentIndex: _currentQuestionIndex,
                            totalQuestions: totalQuestions,
                            currentSegment: currentSegment,
                            onExit: () async {
                              final shouldPop = await _onWillPop();
                              if (shouldPop && context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                        ),

                        // 3. Bottom Glassmorphic Card with Subtitles & Candidate Answer Bar
                        Positioned(
                          bottom: 20.h,
                          left: 16.w,
                          right: 16.w,
                          child: QuestionOverlayCard(
                            segment: currentSegment,
                            state: _state,
                            answerTimerSeconds: _answerTimerSeconds,
                            isLastQuestion:
                                _currentQuestionIndex + 1 == totalQuestions,
                            onNextQuestion: _onNextQuestionPressed,
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildVideoViewport() {
    if (_state == InterviewState.interviewerSpeaking) {
      if (_currentVideoController != null &&
          _currentVideoController!.value.isInitialized) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: VideoPlayer(_currentVideoController!),
        );
      }
    } else if (_state == InterviewState.candidateAnswering) {
      if (_idleLoopController != null &&
          _idleLoopController!.value.isInitialized) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: VideoPlayer(_idleLoopController!),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Center(
        child: ApertureIndicator(
          size: 48.r,
          color: AppColors.primaryAction,
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ApertureIndicator(
              size: 64.r,
              color: AppColors.primaryAction,
            ),
            SizedBox(height: 24.h),
            Text(
              'Preparing AI Interview Sequence',
              style: AppTextStyles.headingSmall(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8.h),
            Text(
              _loadingStatusText,
              style: AppTextStyles.bodySmall(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                color: AppColors.statusError, size: 64.r),
            SizedBox(height: 20.h),
            Text(
              'Interview Generation Error',
              style: AppTextStyles.headingSmall(
                color: AppColors.statusError,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _errorMessage ?? 'Failed to stream interview sequence.',
              style: AppTextStyles.bodyMedium(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 28.h),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAction,
                padding:
                    EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r)),
              ),
              child: const Text('Back to Setup',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
