/// Statut de compte renvoyé par les endpoints de suppression (RGPD).
///
/// Miroir des statuts serveur (`accounts.status`) exposés par
/// `POST /account/request-deletion` et `POST /account/cancel-deletion`.
enum AccountStatus { active, pendingDeletion, deleted }

/// Résultat typé de `POST /account/request-deletion`.
///
/// - Compte anonyme → `status: deleted`, `anonymous: true`,
///   `deletionScheduledAt: null` (suppression immédiate côté serveur).
/// - Compte complet → `status: pendingDeletion`, `anonymous: false`,
///   `deletionScheduledAt` = échéance ISO du délai de 30 jours.
class AccountDeletionResult {
  const AccountDeletionResult({
    required this.status,
    required this.anonymous,
    this.deletionScheduledAt,
  });

  final AccountStatus status;
  final bool anonymous;
  final DateTime? deletionScheduledAt;

  factory AccountDeletionResult.fromJson(Map<String, dynamic> json) {
    return AccountDeletionResult(
      status: _statusFromString(json['status'] as String?),
      anonymous: json['anonymous'] as bool? ?? false,
      deletionScheduledAt: switch (json['deletionScheduledAt']) {
        final String iso => DateTime.tryParse(iso),
        _ => null,
      },
    );
  }

  static AccountStatus _statusFromString(String? raw) {
    return switch (raw) {
      'deleted' => AccountStatus.deleted,
      'pending_deletion' => AccountStatus.pendingDeletion,
      _ => AccountStatus.active,
    };
  }
}
