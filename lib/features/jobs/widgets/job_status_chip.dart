import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/entities/job_entity.dart';

/// Compact status readout chip — JetBrains Mono text + aperture icon.
/// Color and icon rotation convey status without needing colored dots.
class JobStatusChip extends StatefulWidget {
  const JobStatusChip({super.key, required this.status});

  final JobStatus status;

  @override
  State<JobStatusChip> createState() => _JobStatusChipState();
}

class _JobStatusChipState extends State<JobStatusChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotateCtrl;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(JobStatusChip old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) _updateAnimation();
  }

  void _updateAnimation() {
    if (widget.status == JobStatus.processing ||
        widget.status == JobStatus.deductingCredits ||
        widget.status == JobStatus.queued) {
      _rotateCtrl.repeat();
    } else {
      _rotateCtrl.stop();
    }
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    super.dispose();
  }

  Color get _chipColor {
    switch (widget.status) {
      case JobStatus.completed:
        return AppColors.jobCompleted;
      case JobStatus.error:
        return AppColors.jobError;
      case JobStatus.processing:
        return AppColors.jobProcessing;
      default:
        return AppColors.jobQueued;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _chipColor.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _chipColor.withAlpha(60), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _rotateCtrl,
            builder: (_, child) => Transform.rotate(
              angle: _rotateCtrl.value * 2 * 3.14159,
              child: child,
            ),
            child: Icon(Icons.camera_alt_outlined, size: 10, color: _chipColor),
          ),
          const SizedBox(width: 5),
          Text(
            widget.status.firestoreValue,
            style: AppTextStyles.jobStatus(color: _chipColor),
          ),
        ],
      ),
    );
  }
}
