import 'package:ai_studio/domain/entities/job_entity.dart';
import 'package:ai_studio/features/gallery/widgets/image_result_modal.dart';
import 'package:ai_studio/features/mesh/views/mesh_viewer_view.dart';
import 'package:ai_studio/features/video_generation/presentation/widgets/video_player_widget.dart';
import 'package:get/get.dart';

class HomeShellController extends GetxController {
  final RxInt currentIndex = 0.obs;

  void switchTab(int index) {
    currentIndex.value = index;
  }

  /// Switches to Gallery tab and opens the generated asset modal
  void openJobInGallery(JobEntity job) {
    currentIndex.value = 1; // Gallery tab

    final isVideo = job.type == JobType.videoGen ||
        job.type == JobType.videoFaceSwap ||
        (job.outputUrl != null &&
            (job.outputUrl!.toLowerCase().contains('.mp4') ||
                job.outputUrl!.toLowerCase().contains('.mov') ||
                job.outputUrl!.toLowerCase().contains('.webm')));

    final isMesh = job.type == JobType.meshGen ||
        (job.meshUrl != null && job.meshUrl!.isNotEmpty) ||
        (job.outputUrl != null && job.outputUrl!.toLowerCase().contains('.glb'));

    Future.delayed(const Duration(milliseconds: 300), () {
      if (Get.context == null) return;

      if (isMesh) {
        final targetUrl = job.meshUrl ?? job.outputUrl;
        if (targetUrl != null && targetUrl.isNotEmpty) {
          MeshViewerModal.show(Get.context!, meshUrl: targetUrl);
        }
      } else if (isVideo && job.outputUrl != null && job.outputUrl!.isNotEmpty) {
        VideoPlayerModal.show(
          Get.context!,
          videoUrl: job.outputUrl!,
          title: job.params.userPrompt ??
              (job.type == JobType.videoFaceSwap
                  ? 'AI Face Swap Video'
                  : 'AI Video Result'),
          job: job,
        );
      } else if (job.outputUrl != null && job.outputUrl!.isNotEmpty) {
        ImageResultModal.show(Get.context!, imageUrl: job.outputUrl!, job: job);
      }
    });
  }
}
