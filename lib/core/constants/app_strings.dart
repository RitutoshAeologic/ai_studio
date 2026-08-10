/// Global string constants for AI Studio.
/// All static user-facing text must be declared here to avoid hardcoded inline strings.
// ignore_for_file: avoid_classes_with_only_static_members
abstract class AppStrings {
  static const String appName = 'AI Studio';

  // ── Auth Headings & Subtitles ──────────────────────────────────────────────
  static const String welcomeBack = 'Welcome back.';
  static const String signInSubtitle = 'Sign in to your AI Studio account';
  static const String createAccountTitle = 'Create account.';
  static const String signUpSubtitle = 'Start generating AI images, 3D models & more';

  // ── Onboarding Badge ───────────────────────────────────────────────────────
  static const String freeCreditsBadgeTitle = '100 free credits on sign up';
  static const String freeCreditsBadgeSubtext =
      'Generate AI images, 3D models and video clips';

  // ── Form Field Labels & Hints ──────────────────────────────────────────────
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

  // ── Validation Errors ──────────────────────────────────────────────────────
  static const String nameRequiredError = 'Name is required';
  static const String emailRequiredError = 'Email is required';
  static const String emailInvalidError = 'Enter a valid email';
  static const String passwordRequiredError = 'Password is required';
  static const String passwordLengthError = 'Minimum 8 characters';
  static const String confirmPasswordRequiredError = 'Please confirm your password';
  static const String passwordsDoNotMatchError = 'Passwords do not match';

  // ── Buttons & Actions ──────────────────────────────────────────────────────
  static const String signIn = 'Sign In';
  static const String createAccountButton = 'Create Account';
  static const String forgotPassword = 'Forgot password?';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String createOne = 'Create one';
  static const String signInLink = 'Sign in';
  static const String back = 'Back';
  static const String loadingEllipsis = 'Loading…';
  static const String termsAndPrivacyNotice =
      'By creating an account you agree to our Terms of Service & Privacy Policy';

  // ── Navigation Tab Labels ──────────────────────────────────────────────────
  static const String tabGenerate = 'Generate';
  static const String tabGallery = 'Gallery';
  static const String tabWallet = 'Wallet';
  static const String tabProfile = 'Profile';

  // ── Credit Wallet ──────────────────────────────────────────────────────────
  static const String creditsLabel = 'credits';
  static const String walletTitle = 'Wallet';
  static const String walletBalanceLabel = 'Balance';
  static const String walletDebugTitle = 'Wallet Debug Panel';
  static const String addTestCredits = 'Add 100 Test Credits';
  static const String addingCredits = 'Adding…';
  static const String creditsAdded = 'Credits added';
  static const String rawWalletDoc = 'Raw Firestore doc';

  // ── Feature Names ──────────────────────────────────────────────────────────
  static const String imageTo3d = 'Image to 3D';
  static const String themeChange = 'Theme Change';
  static const String backgroundChange = 'Background Change';
  static const String videoGen = '10-Sec Video';
  static const String gallery = 'Gallery';

  // ── Job Status Strings (JetBrains Mono readouts) ──────────────────────────
  static const String jobStatusIdle = 'idle';
  static const String jobStatusPending = 'pending';
  static const String jobStatusDeductingCredits = 'deducting_credits';
  static const String jobStatusQueued = 'queued';
  static const String jobStatusProcessing = 'processing';
  static const String jobStatusCompleted = 'completed';
  static const String jobStatusError = 'error';

  // ── Job Submission ─────────────────────────────────────────────────────────
  static const String generateJob = 'Generate';
  static const String generatingJob = 'Generating…';
  static const String jobSubmitted = 'Job submitted';
  static const String viewResult = 'View Result';
  static const String retryJob = 'Retry';

  // ── Error Messages ─────────────────────────────────────────────────────────
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String submit = 'Submit';
  static const String insufficientCredits = 'Insufficient credits';
  static const String networkError = 'Network connection error';
  static const String unknownError = 'Something went wrong. Please try again.';
  static const String invalidEmailOrPassword =
      'Invalid email or password. Please try again.';
  static const String signUpFailedEmailInUse =
      'Sign up failed. The email may already be in use.';
}
