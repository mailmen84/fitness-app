class AppRoutePaths {
  const AppRoutePaths._();

  static const welcome = '/welcome';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const onboardingGoal = '/onboarding/goal';
  static const onboardingStats = '/onboarding/stats';
  static const onboardingActivity = '/onboarding/activity';
  static const onboardingTarget = '/onboarding/target';
  static const today = '/today';
  static const nutrition = '/nutrition';
  static const add = '/add';
  static const addQuick = '/add/quick';
  static const addSearch = '/add/search';
  static const addScan = '/add/scan';
  static const addScanReview = '/add/scan/review';
  static const addCustom = '/add/custom';
  static const addFoodBase = '/add/food';
  static const addMealBase = '/add/meal';
  static const progress = '/progress';
  static const progressWeight = '/progress/weight';
  static const progressAddWeight = '/progress/weight/add';
  static const progressMeasurements = '/progress/measurements';
  static const progressAddMeasurement = '/progress/measurements/add';
  static const more = '/more';
  static const moreProfile = '/more/profile';
  static const moreGoals = '/more/goals';
  static const morePreferences = '/more/preferences';
  static const moreDietSetup = '/more/diet-setup';
  static const moreSupport = '/more/support';
  static const ped = '/more/ped';

  static String addFoodDetail(String foodId) => '$addFoodBase/$foodId';
  static String addMealDetail(String entryId) => '$addMealBase/$entryId';
}
