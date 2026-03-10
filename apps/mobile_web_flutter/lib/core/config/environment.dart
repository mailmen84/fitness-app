class Environment {
  const Environment._();

  static const appName = 'Fitness App';
  static const defaultApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
}

