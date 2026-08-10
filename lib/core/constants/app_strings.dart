/// Global string constants for AI Studio.
/// All static user-facing text must be declared here to avoid hardcoded inline strings.
abstract class AppStrings {
  static const String appName = 'AI Studio';

  // Auth Headings & Subtitles
  static const String welcomeBack = 'Welcome back';
  static const String signInSubtitle = 'Sign in to your AI Studio account';
  static const String createAccountTitle = 'Create your account';
  static const String signUpSubtitle = 'Start generating AI images, 3D models & videos';

  // Badge & Reward Strings
  static const String freeCreditsBadgeTitle = '100 Free Credits on Sign Up';
  static const String freeCreditsBadgeSubtext = 'Generate AI images, 3D models and video clips';

  // Form Field Labels & Hints
  static const String fullNameLabel = 'Full Name';
  static const String fullNameHint = 'Enter your full name';
  static const String emailLabel = 'Email';
  static const String emailHint = 'Enter your email';
  static const String passwordLabel = 'Password';
  static const String passwordLoginHint = 'Enter your password';
  static const String passwordSignupHint = 'Create a strong password';
  static const String confirmPasswordLabel = 'Confirm Password';
  static const String confirmPasswordHint = 'Repeat your password';
  static const String passwordRequirementHint = 'At least 8 characters';

  // Validation Errors
  static const String nameRequiredError = 'Name is required';
  static const String emailRequiredError = 'Email is required';
  static const String emailInvalidError = 'Enter a valid email';
  static const String passwordRequiredError = 'Password is required';
  static const String passwordLengthError = 'Minimum 8 characters';
  static const String confirmPasswordRequiredError = 'Please confirm your password';
  static const String passwordsDoNotMatchError = 'Passwords do not match';

  // Buttons & Navigation Actions
  static const String signIn = 'Sign In';
  static const String createAccountButton = 'Create Account';
  static const String forgotPassword = 'Forgot password?';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String createOne = 'Create one';
  static const String back = 'Back';
  static const String loadingEllipsis = 'Loading…';
  static const String termsAndPrivacyNotice = 'By creating an account, you agree to our\nTerms of Service & Privacy Policy';

  // Features
  static const String imageTo3d = 'Image to 3D';
  static const String themeChange = 'Theme Change';
  static const String backgroundChange = 'Background Change';
  static const String videoGen = '10-Sec Video';
  static const String gallery = 'Gallery';

  // Error Messages
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String submit = 'Submit';
  static const String insufficientCredits = 'Insufficient credits';
  static const String networkError = 'Network connection error';
  static const String unknownError = 'Something went wrong. Please try again.';
  static const String invalidEmailOrPassword = 'Invalid email or password. Please try again.';
  static const String signUpFailedEmailInUse = 'Sign up failed. The email may already be in use.';

  // Image Validation Errors
  static const String imageInvalidFormat = 'Unsupported image format. Please select a JPEG, PNG, or WEBP image.';
  static const String imageTooSmall = 'Image file is too small or empty. Please select a valid image.';
  static const String imageTooLarge = 'Image file exceeds the 20MB limit. Please select a smaller file.';
  static const String imageLowResolution = 'Image resolution is too low. Minimum required resolution is 256x256 pixels.';
  static const String imageHighResolution = 'Image resolution exceeds 4096x4096 pixels. Please select a smaller image.';
  static const String imageCorrupted = 'Corrupted or unreadable image file. Please select a different image.';
  static const String imageBlankOrExtremeBrightness = 'This image appears to be blank or too dark/bright. Please select a different image.';
  static const String imageNoSubjectDetected = 'No usable subject detected. Please select an image containing a clear object or person.';
  static const String imageTooBlurry = 'This image is too blurry for AI processing. Please select a sharper image.';
  static const String imageLowContrast = 'This image lacks visual detail or contrast. Please select a clearer image.';
}
