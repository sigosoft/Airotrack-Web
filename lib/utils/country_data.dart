class CountryInfo {
  final String name;
  final String code;
  final String dialCode;
  final String flag;

  const CountryInfo({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountryInfo &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          dialCode == other.dialCode;

  @override
  int get hashCode => code.hashCode ^ dialCode.hashCode;
}

class CountryData {
  static const CountryInfo defaultCountry = CountryInfo(
    name: 'India',
    code: 'IN',
    dialCode: '+91',
    flag: '🇮🇳',
  );

  static const List<CountryInfo> countries = [
    CountryInfo(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
    CountryInfo(name: 'United Arab Emirates', code: 'AE', dialCode: '+971', flag: '🇦🇪'),
    CountryInfo(name: 'Saudi Arabia', code: 'SA', dialCode: '+966', flag: '🇸🇦'),
    CountryInfo(name: 'Qatar', code: 'QA', dialCode: '+974', flag: '🇶🇦'),
    CountryInfo(name: 'Kuwait', code: 'KW', dialCode: '+965', flag: '🇰🇼'),
    CountryInfo(name: 'Oman', code: 'OM', dialCode: '+968', flag: '🇴🇲'),
    CountryInfo(name: 'Bahrain', code: 'BH', dialCode: '+973', flag: '🇧🇭'),
    CountryInfo(name: 'United States', code: 'US', dialCode: '+1', flag: '🇺🇸'),
    CountryInfo(name: 'United Kingdom', code: 'GB', dialCode: '+44', flag: '🇬🇧'),
    CountryInfo(name: 'Canada', code: 'CA', dialCode: '+1', flag: '🇨🇦'),
    CountryInfo(name: 'Australia', code: 'AU', dialCode: '+61', flag: '🇦🇺'),
    CountryInfo(name: 'Singapore', code: 'SG', dialCode: '+65', flag: '🇸🇬'),
    CountryInfo(name: 'Malaysia', code: 'MY', dialCode: '+60', flag: '🇲🇾'),
    CountryInfo(name: 'Germany', code: 'DE', dialCode: '+49', flag: '🇩🇪'),
    CountryInfo(name: 'France', code: 'FR', dialCode: '+33', flag: '🇫🇷'),
    CountryInfo(name: 'Italy', code: 'IT', dialCode: '+39', flag: '🇮🇹'),
    CountryInfo(name: 'Spain', code: 'ES', dialCode: '+34', flag: '🇪🇸'),
    CountryInfo(name: 'Netherlands', code: 'NL', dialCode: '+31', flag: '🇳🇱'),
    CountryInfo(name: 'Switzerland', code: 'CH', dialCode: '+41', flag: '🇨🇭'),
    CountryInfo(name: 'New Zealand', code: 'NZ', dialCode: '+64', flag: '🇳🇿'),
    CountryInfo(name: 'South Africa', code: 'ZA', dialCode: '+27', flag: '🇿🇦'),
    CountryInfo(name: 'Brazil', code: 'BR', dialCode: '+55', flag: '🇧🇷'),
    CountryInfo(name: 'Japan', code: 'JP', dialCode: '+81', flag: '🇯🇵'),
    CountryInfo(name: 'China', code: 'CN', dialCode: '+86', flag: '🇨🇳'),
    CountryInfo(name: 'South Korea', code: 'KR', dialCode: '+82', flag: '🇰🇷'),
    CountryInfo(name: 'Indonesia', code: 'ID', dialCode: '+62', flag: '🇮🇩'),
    CountryInfo(name: 'Philippines', code: 'PH', dialCode: '+63', flag: '🇵🇭'),
    CountryInfo(name: 'Thailand', code: 'TH', dialCode: '+66', flag: '🇹🇭'),
    CountryInfo(name: 'Vietnam', code: 'VN', dialCode: '+84', flag: '🇻🇳'),
    CountryInfo(name: 'Bangladesh', code: 'BD', dialCode: '+880', flag: '🇧🇩'),
    CountryInfo(name: 'Pakistan', code: 'PK', dialCode: '+92', flag: '🇵🇰'),
    CountryInfo(name: 'Sri Lanka', code: 'LK', dialCode: '+94', flag: '🇱🇰'),
    CountryInfo(name: 'Nepal', code: 'NP', dialCode: '+977', flag: '🇳🇵'),
    CountryInfo(name: 'Egypt', code: 'EG', dialCode: '+20', flag: '🇪🇬'),
    CountryInfo(name: 'Nigeria', code: 'NG', dialCode: '+234', flag: '🇳🇬'),
    CountryInfo(name: 'Kenya', code: 'KE', dialCode: '+254', flag: '🇰🇪'),
    CountryInfo(name: 'Russia', code: 'RU', dialCode: '+7', flag: '🇷🇺'),
    CountryInfo(name: 'Turkey', code: 'TR', dialCode: '+90', flag: '🇹🇷'),
    CountryInfo(name: 'Mexico', code: 'MX', dialCode: '+52', flag: '🇲🇽'),
    CountryInfo(name: 'Argentina', code: 'AR', dialCode: '+54', flag: '🇦🇷'),
    CountryInfo(name: 'Ireland', code: 'IE', dialCode: '+353', flag: '🇮🇪'),
    CountryInfo(name: 'Sweden', code: 'SE', dialCode: '+46', flag: '🇸🇪'),
    CountryInfo(name: 'Norway', code: 'NO', dialCode: '+47', flag: '🇳🇴'),
    CountryInfo(name: 'Denmark', code: 'DK', dialCode: '+45', flag: '🇩🇰'),
    CountryInfo(name: 'Poland', code: 'PL', dialCode: '+48', flag: '🇵🇱'),
    CountryInfo(name: 'Portugal', code: 'PT', dialCode: '+351', flag: '🇵🇹'),
    CountryInfo(name: 'Belgium', code: 'BE', dialCode: '+32', flag: '🇧🇪'),
    CountryInfo(name: 'Austria', code: 'AT', dialCode: '+43', flag: '🇦🇹'),
  ];

  /// Auto-detect country and local phone number from input string
  /// (e.g. "+971501234567", "00971 50 1234567", "+14155552671", etc.)
  static ({CountryInfo country, String cleanNumber})? detectCountryAndNumber(String input) {
    String text = input.trim();
    if (text.isEmpty) return null;

    if (text.startsWith('00')) {
      text = '+${text.substring(2)}';
    }

    if (text.startsWith('+')) {
      // Sort countries by dialCode length descending to match +971 before +9 etc.
      final sorted = List<CountryInfo>.from(countries)
        ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));

      for (final country in sorted) {
        if (text.startsWith(country.dialCode)) {
          final remaining = text.substring(country.dialCode.length).trim();
          return (country: country, cleanNumber: remaining);
        }
      }
    }
    return null;
  }

  /// Find country by dial code or country code string
  static CountryInfo findByDialCode(String? dialCode) {
    if (dialCode == null || dialCode.trim().isEmpty) return defaultCountry;
    final clean = dialCode.replaceAll(' ', '').trim();
    final normalized = clean.startsWith('+') ? clean : '+$clean';
    return countries.firstWhere(
      (c) => c.dialCode == normalized || c.code.toUpperCase() == clean.toUpperCase(),
      orElse: () => defaultCountry,
    );
  }
}
