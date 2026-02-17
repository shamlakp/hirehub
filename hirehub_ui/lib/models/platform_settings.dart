class PlatformSettings {
  final String phoneNumber;
  final String whatsappNumber;
  final String email;
  final String address;
  final String? whatsappLink;

  PlatformSettings({
    required this.phoneNumber,
    required this.whatsappNumber,
    required this.email,
    required this.address,
    this.whatsappLink,
  });

  factory PlatformSettings.fromJson(Map<String, dynamic> json) {
    return PlatformSettings(
      phoneNumber: json['phone_number'] ?? '',
      whatsappNumber: json['whatsapp_number'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      whatsappLink: json['whatsapp_link'],
    );
  }
}
