import '../constants/app_strings.dart';
import 'failure.dart';

/// Central error -> UI message mapper. UI widgets consume mapped string messages only.
abstract class ErrorHandler {
  static String map(Failure failure) {
    switch (failure) {
      case NetworkFailure():
        return AppStrings.networkError;
      case InsufficientCreditsFailure():
        return AppStrings.insufficientCredits;
      case JobFailedFailure(:final message):
        return message.isNotEmpty ? message : AppStrings.unknownError;
      case AuthFailure(:final message):
        return message.isNotEmpty ? message : AppStrings.unknownError;
      case UnknownFailure(:final message):
        return message.isNotEmpty ? message : AppStrings.unknownError;
    }
  }
}
