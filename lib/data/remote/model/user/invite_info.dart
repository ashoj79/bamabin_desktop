class InviteInfo {
  final int invitesCount;
  final bool isInvited;
  final String inviteCode;

  InviteInfo({
    required this.invitesCount,
    required this.isInvited,
    required this.inviteCode,
  });

  factory InviteInfo.fromJson(Map<String, dynamic> json) => InviteInfo(
    invitesCount: json['invites_count'] ?? 0,
    isInvited: json['is_invited'] ?? false,
    inviteCode: json['invite_code'] ?? '',
  );
}
