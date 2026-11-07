/// Typed error vocabulary from docs/contracts/ERROR_CODES.md.
/// UI maps each code to a safe explanation; retry only when retryable.
library;

enum FcErrorCode {
  authRequired,
  circleForbidden,
  adultOnly,
  minorCommerceBlocked,
  recipeUnverified,
  allergenUncertain,
  planInfeasible,
  budgetEstimateUnavailable,
  ballotExpired,
  voteAlreadyCast,
  rateLimited,
  subscriptionNotVerified,
  mediaLicenseMissing,
  contentModerationRequired,
  conflictRevision,
  offlineNotSupported,
  validation,
}

class FcException implements Exception {
  const FcException(this.code, [this.detail]);

  final FcErrorCode code;
  final String? detail;

  String get wireCode => switch (code) {
    FcErrorCode.authRequired => 'AUTH_REQUIRED',
    FcErrorCode.circleForbidden => 'CIRCLE_FORBIDDEN',
    FcErrorCode.adultOnly => 'ADULT_ONLY',
    FcErrorCode.minorCommerceBlocked => 'MINOR_COMMERCE_BLOCKED',
    FcErrorCode.recipeUnverified => 'RECIPE_UNVERIFIED',
    FcErrorCode.allergenUncertain => 'ALLERGEN_UNCERTAIN',
    FcErrorCode.planInfeasible => 'PLAN_INFEASIBLE',
    FcErrorCode.budgetEstimateUnavailable => 'BUDGET_ESTIMATE_UNAVAILABLE',
    FcErrorCode.ballotExpired => 'BALLOT_EXPIRED',
    FcErrorCode.voteAlreadyCast => 'VOTE_ALREADY_CAST',
    FcErrorCode.rateLimited => 'RATE_LIMITED',
    FcErrorCode.subscriptionNotVerified => 'SUBSCRIPTION_NOT_VERIFIED',
    FcErrorCode.mediaLicenseMissing => 'MEDIA_LICENSE_MISSING',
    FcErrorCode.contentModerationRequired => 'CONTENT_MODERATION_REQUIRED',
    FcErrorCode.conflictRevision => 'CONFLICT_REVISION',
    FcErrorCode.offlineNotSupported => 'OFFLINE_NOT_SUPPORTED',
    FcErrorCode.validation => 'VALIDATION',
  };

  bool get retryable => switch (code) {
    FcErrorCode.offlineNotSupported ||
    FcErrorCode.rateLimited ||
    FcErrorCode.conflictRevision => true,
    _ => false,
  };

  /// Safe, non-shaming explanation. Never blames the user or discloses
  /// private backend detail.
  String get safeMessage => switch (code) {
    FcErrorCode.authRequired => 'Sign in again to continue.',
    FcErrorCode.circleForbidden => 'You do not have access to this household.',
    FcErrorCode.adultOnly => 'An adult needs to do this step.',
    FcErrorCode.minorCommerceBlocked =>
      'Purchases are only available to adults.',
    FcErrorCode.recipeUnverified =>
      'This recipe is still being checked. Try another one.',
    FcErrorCode.allergenUncertain =>
      'We could not confirm this food is safe for your household.',
    FcErrorCode.planInfeasible => 'We could not build a plan with these limits. Try relaxing budget or time.',
    FcErrorCode.budgetEstimateUnavailable =>
      'Some prices are estimates or missing, so the total is not final.',
    FcErrorCode.ballotExpired => 'This vote has closed.',
    FcErrorCode.voteAlreadyCast => 'Your vote was already counted.',
    FcErrorCode.rateLimited => 'That is used up for now. Check back later.',
    FcErrorCode.subscriptionNotVerified =>
      'We could not verify this purchase yet.',
    FcErrorCode.mediaLicenseMissing => 'This image is not cleared to show yet.',
    FcErrorCode.contentModerationRequired =>
      'This needs an adult review before sharing.',
    FcErrorCode.conflictRevision =>
      'This changed somewhere else. Refresh and try again.',
    FcErrorCode.offlineNotSupported =>
      'You are offline. This will retry when you reconnect.',
    FcErrorCode.validation => detail ?? 'Check the details and try again.',
  };

  @override
  String toString() => '$wireCode: $safeMessage';
}
