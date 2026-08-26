import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/unfocus_on_tap.dart';
import '../../wallet/controllers/wallet_controller.dart';
import '../models/interview_models.dart';
import '../services/interview_api_service.dart';
import 'interactive_interview_view.dart';

class InterviewSetupView extends StatefulWidget {
  const InterviewSetupView({super.key});

  @override
  State<InterviewSetupView> createState() => _InterviewSetupViewState();
}

class _InterviewSetupViewState extends State<InterviewSetupView> {
  final _nameCtrl = TextEditingController(text: PreloadedInterviewData.defaultCandidate.name);
  final _emailCtrl = TextEditingController(text: PreloadedInterviewData.defaultCandidate.email);
  final _roleCtrl = TextEditingController(text: PreloadedInterviewData.defaultCandidate.role);
  final String _actorVideoUrl = PreloadedInterviewData.defaultActorVideoUrl;
  final List<InterviewQuestion> _questions = List.from(PreloadedInterviewData.defaultQuestions);

  bool _isStarting = false;
  bool _showQuestionsList = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _roleCtrl.dispose();
    super.dispose();
  }

  Future<void> _startInterview() async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in candidate name and email.',
            style: AppTextStyles.bodyMedium(color: Colors.white),
          ),
          backgroundColor: AppColors.statusError,
        ),
      );
      return;
    }

    await HapticFeedback.mediumImpact();
    setState(() => _isStarting = true);

    try {
      final request = GenerateInterviewSequenceRequest(
        avatarMediaUrl: _actorVideoUrl,
        candidate: InterviewCandidate(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          role: _roleCtrl.text.trim(),
          difficulty: 'easy',
        ),
        generateIdleLoop: true,
        questions: _questions,
      );

      final response = await InterviewApiService.startInterviewSequence(request);

      if (mounted) {
        await Get.to(() => InteractiveInterviewView(
              interviewId: response.interviewId,
              candidate: request.candidate,
              initialQuestions: _questions,
            ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error starting interview: ${e.toString().replaceFirst('Exception: ', '')}',
              style: AppTextStyles.bodyMedium(color: Colors.white),
            ),
            backgroundColor: AppColors.statusError,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletCtrl = Get.isRegistered<WalletController>() ? Get.find<WalletController>() : null;

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'AI Interview Studio',
          style: AppTextStyles.headingM(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 22.r),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          if (walletCtrl != null)
            Obx(() {
              final balance = walletCtrl.wallet.value?.balance ?? 0;
              return Container(
                margin: EdgeInsets.only(right: 16.w),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.creditGoldBg,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.creditGoldIcon, width: 1.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: AppColors.creditGoldIcon, size: 16.r),
                    SizedBox(width: 4.w),
                    Text(
                      '$balance Credits',
                      style: AppTextStyles.caption(
                        color: AppColors.creditGoldTitle,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
      body: UnfocusOnTap(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Introduction Banner
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryAction.withAlpha(40),
                      AppColors.surfaceCard,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.primaryAction.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44.r,
                      height: 44.r,
                      decoration: const BoxDecoration(
                        color: AppColors.emberSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.smart_toy_rounded,
                        size: 22.r,
                        color: AppColors.primaryAction,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Interactive AI Interviewer',
                            style: AppTextStyles.headingSmall(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Live Q&A simulation with lip-synced video and candidate timer.',
                            style: AppTextStyles.caption(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // 2. Candidate Information Form
              Text(
                'CANDIDATE DETAILS',
                style: AppTextStyles.labelSmall(color: AppColors.textMuted),
              ),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: AppColors.borderSubtle, width: 1.r),
                ),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameCtrl,
                      label: 'Candidate Name',
                      icon: Icons.person_outline_rounded,
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: _emailCtrl,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: _roleCtrl,
                      label: 'Target Role',
                      icon: Icons.work_outline_rounded,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // 3. AI Interviewer Avatar Card
              Text(
                'AI INTERVIEWER AVATAR',
                style: AppTextStyles.labelSmall(color: AppColors.textMuted),
              ),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: AppColors.borderSubtle, width: 1.r),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50.r,
                      height: 50.r,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceInput,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: AppColors.primaryAction, width: 1.r),
                      ),
                      child: Icon(
                        Icons.face_retouching_natural_rounded,
                        color: AppColors.primaryAction,
                        size: 26.r,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aeologic Bot (Male Voice)',
                            style: AppTextStyles.bodyMedium(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Model: SadTalker / LivePortrait 1080p',
                            style: AppTextStyles.caption(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.statusSuccessSoft,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'Ready',
                        style: AppTextStyles.caption(
                          color: AppColors.statusSuccess,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // 4. Questions Preview Accordion
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'INTERVIEW QUESTIONS (${_questions.length})',
                    style: AppTextStyles.labelSmall(color: AppColors.textMuted),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showQuestionsList = !_showQuestionsList),
                    child: Row(
                      children: [
                        Text(
                          _showQuestionsList ? 'Collapse' : 'View All',
                          style: AppTextStyles.caption(
                            color: AppColors.primaryAction,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          _showQuestionsList
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primaryAction,
                          size: 16.r,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              if (_showQuestionsList)
                Column(
                  children: _questions.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final q = entry.value;
                    return Container(
                      margin: EdgeInsets.only(bottom: 8.h),
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: AppColors.borderSubtle, width: 1.r),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppColors.emberSoft,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              'Q${idx + 1}',
                              style: AppTextStyles.caption(
                                color: AppColors.primaryAction,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (q.tag != null)
                                  Text(
                                    q.tag!,
                                    style: AppTextStyles.caption(
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                SizedBox(height: 2.h),
                                Text(
                                  q.text,
                                  style: AppTextStyles.bodySmall(color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
              else
                Container(
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: AppColors.borderSubtle, width: 1.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.list_alt_rounded, color: AppColors.primaryAction, size: 20.r),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          '12 Technical & Behavioral Questions configured for ${PreloadedInterviewData.defaultCandidate.role}',
                          style: AppTextStyles.bodySmall(color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 32.h),

              // 5. Start CTA Button
              Column(
                children: [
                  AppButton(
                    label: _isStarting ? 'Preparing Sequence...' : 'Start AI Interview',
                    isLoading: _isStarting,
                    onPressed: _isStarting ? null : _startInterview,
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bolt_rounded, size: 14.r, color: AppColors.creditGoldIcon),
                      SizedBox(width: 4.w),
                      Text(
                        'Deducts 50 Credits per complete interview session',
                        style: AppTextStyles.bodySmall(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceInput,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.borderSubtle, width: 1.r),
      ),
      child: TextField(
        controller: controller,
        style: AppTextStyles.bodyM(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTextStyles.caption(color: AppColors.textMuted),
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18.r),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        ),
      ),
    );
  }
}
