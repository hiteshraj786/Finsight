class AppConstants {
  AppConstants._();

  // Timing
  static const int splashDuration = 2; // seconds
  static const int otpResendDuration = 300; // 5 minutes in seconds
  static const int otpLength = 6;
  static const int pinLength = 6;

  // Animations
  static const int pageTransitionDuration = 300; // ms
  static const int fadeInDuration = 500; // ms

  // Onboarding Text Data
  static const List<Map<String, String>> onboardingData = [
    {
      'title': 'Gain total control\nof your money',
      'subtitle': 'Become your own money manager\nand make every cent count',
    },
    {
      'title': 'Know where your\nmoney goes',
      'subtitle':
          'Track your transaction easily,\nwith categories and financial report',
    },
    {
      'title': 'Planning ahead',
      'subtitle': 'Setup your budget for each category\nso you in control',
    },
  ];
}
