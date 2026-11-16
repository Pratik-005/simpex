class CurrencyItem {
  final String code;
  final String name;
  final String symbol;

  const CurrencyItem({
    required this.code,
    required this.name,
    String? symbol,
  }) : symbol = symbol ?? code;

  String get displayName => '$code — $name';
  String get formattedCode => symbol != code ? '$code ($symbol)' : code;
}

class CurrencyConstants {
  CurrencyConstants._();

  static const CurrencyItem defaultCurrency = CurrencyItem(
    code: 'INR',
    name: 'Indian rupee',
    symbol: '₹',
  );

  static const List<CurrencyItem> currencies = [
    CurrencyItem(code: 'AED', name: 'UAE dirham', symbol: 'د.إ'),
    CurrencyItem(code: 'AFN', name: 'Afghan afghani', symbol: '؋'),
    CurrencyItem(code: 'ALL', name: 'Albanian lek', symbol: 'L'),
    CurrencyItem(code: 'AMD', name: 'Armenian dram', symbol: '֏'),
    CurrencyItem(code: 'AOA', name: 'Angolan kwanza', symbol: 'Kz'),
    CurrencyItem(code: 'ARS', name: 'Argentine peso', symbol: '\$'),
    CurrencyItem(code: 'AUD', name: 'Australian dollar', symbol: 'A\$'),
    CurrencyItem(code: 'AWG', name: 'Aruban florin', symbol: 'ƒ'),
    CurrencyItem(code: 'AZN', name: 'Azerbaijani manat', symbol: '₼'),
    CurrencyItem(code: 'BAM', name: 'Bosnia and Herzegovina convertible mark', symbol: 'KM'),
    CurrencyItem(code: 'BBD', name: 'Barbados dollar', symbol: 'Bds\$'),
    CurrencyItem(code: 'BDT', name: 'Bangladeshi taka', symbol: '৳'),
    CurrencyItem(code: 'BGN', name: 'Bulgarian lev', symbol: 'лв'),
    CurrencyItem(code: 'BHD', name: 'Bahraini dinar', symbol: '.د.ب'),
    CurrencyItem(code: 'BIF', name: 'Burundian franc', symbol: 'FBu'),
    CurrencyItem(code: 'BMD', name: 'Bermudian dollar', symbol: '\$'),
    CurrencyItem(code: 'BND', name: 'Brunei dollar', symbol: 'B\$'),
    CurrencyItem(code: 'BOB', name: 'Bolivian boliviano', symbol: 'Bs.'),
    CurrencyItem(code: 'BRL', name: 'Brazilian real', symbol: 'R\$'),
    CurrencyItem(code: 'BSD', name: 'Bahamian dollar', symbol: 'B\$'),
    CurrencyItem(code: 'BTN', name: 'Bhutanese ngultrum', symbol: 'Nu.'),
    CurrencyItem(code: 'BWP', name: 'Botswana pula', symbol: 'P'),
    CurrencyItem(code: 'BYN', name: 'Belarusian ruble', symbol: 'Br'),
    CurrencyItem(code: 'BZD', name: 'Belize dollar', symbol: 'BZ\$'),
    CurrencyItem(code: 'CAD', name: 'Canadian dollar', symbol: 'CA\$'),
    CurrencyItem(code: 'CDF', name: 'Congolese franc', symbol: 'FC'),
    CurrencyItem(code: 'CHF', name: 'Swiss franc', symbol: 'CHF'),
    CurrencyItem(code: 'CLP', name: 'Chilean peso', symbol: '\$'),
    CurrencyItem(code: 'CNY', name: 'Chinese yuan renminbi', symbol: '¥'),
    CurrencyItem(code: 'COP', name: 'Colombian peso', symbol: '\$'),
    CurrencyItem(code: 'CRC', name: 'Costa Rican colon', symbol: '₡'),
    CurrencyItem(code: 'CUP', name: 'Cuban peso', symbol: '₱'),
    CurrencyItem(code: 'CVE', name: 'Cape Verdean escudo', symbol: 'Esc'),
    CurrencyItem(code: 'CZK', name: 'Czech koruna', symbol: 'Kč'),
    CurrencyItem(code: 'DJF', name: 'Djiboutian franc', symbol: 'Fdj'),
    CurrencyItem(code: 'DKK', name: 'Danish krone', symbol: 'kr'),
    CurrencyItem(code: 'DOP', name: 'Dominican peso', symbol: 'RD\$'),
    CurrencyItem(code: 'DZD', name: 'Algerian dinar', symbol: 'د.ج'),
    CurrencyItem(code: 'EGP', name: 'Egyptian pound', symbol: 'E£'),
    CurrencyItem(code: 'ERN', name: 'Eritrean nakfa', symbol: 'Nfk'),
    CurrencyItem(code: 'ETB', name: 'Ethiopian birr', symbol: 'Br'),
    CurrencyItem(code: 'EUR', name: 'Euro', symbol: '€'),
    CurrencyItem(code: 'FJD', name: 'Fiji dollar', symbol: 'FJ\$'),
    CurrencyItem(code: 'FKP', name: 'Falkland Islands pound', symbol: '£'),
    CurrencyItem(code: 'GBP', name: 'Pound sterling', symbol: '£'),
    CurrencyItem(code: 'GEL', name: 'Georgian lari', symbol: '₾'),
    CurrencyItem(code: 'GHS', name: 'Ghanaian cedi', symbol: 'GH₵'),
    CurrencyItem(code: 'GIP', name: 'Gibraltar pound', symbol: '£'),
    CurrencyItem(code: 'GMD', name: 'Gambian dalasi', symbol: 'D'),
    CurrencyItem(code: 'GNF', name: 'Guinean franc', symbol: 'FG'),
    CurrencyItem(code: 'GTQ', name: 'Guatemalan quetzal', symbol: 'Q'),
    CurrencyItem(code: 'GYD', name: 'Guyanese dollar', symbol: 'G\$'),
    CurrencyItem(code: 'HKD', name: 'Hong Kong dollar', symbol: 'HK\$'),
    CurrencyItem(code: 'HNL', name: 'Honduran lempira', symbol: 'L'),
    CurrencyItem(code: 'HTG', name: 'Haitian gourde', symbol: 'G'),
    CurrencyItem(code: 'HUF', name: 'Hungarian forint', symbol: 'Ft'),
    CurrencyItem(code: 'IDR', name: 'Indonesian rupiah', symbol: 'Rp'),
    CurrencyItem(code: 'ILS', name: 'Israeli new shekel', symbol: '₪'),
    CurrencyItem(code: 'INR', name: 'Indian rupee', symbol: '₹'),
    CurrencyItem(code: 'IQD', name: 'Iraqi dinar', symbol: 'ع.د'),
    CurrencyItem(code: 'IRR', name: 'Iranian rial', symbol: '﷼'),
    CurrencyItem(code: 'ISK', name: 'Icelandic krona', symbol: 'kr'),
    CurrencyItem(code: 'JMD', name: 'Jamaican dollar', symbol: 'J\$'),
    CurrencyItem(code: 'JOD', name: 'Jordanian dinar', symbol: 'د.ا'),
    CurrencyItem(code: 'JPY', name: 'Japanese yen', symbol: '¥'),
    CurrencyItem(code: 'KES', name: 'Kenyan shilling', symbol: 'KSh'),
    CurrencyItem(code: 'KGS', name: 'Kyrgyzstani som', symbol: 'сом'),
    CurrencyItem(code: 'KHR', name: 'Cambodian riel', symbol: '៛'),
    CurrencyItem(code: 'KMF', name: 'Comorian franc', symbol: 'CF'),
    CurrencyItem(code: 'KPW', name: 'North Korean won', symbol: '₩'),
    CurrencyItem(code: 'KRW', name: 'South Korean won', symbol: '₩'),
    CurrencyItem(code: 'KWD', name: 'Kuwaiti dinar', symbol: 'د.ك'),
    CurrencyItem(code: 'KYD', name: 'Cayman Islands dollar', symbol: 'CI\$'),
    CurrencyItem(code: 'KZT', name: 'Kazakhstani tenge', symbol: '₸'),
    CurrencyItem(code: 'LAK', name: 'Lao kip', symbol: '₭'),
    CurrencyItem(code: 'LBP', name: 'Lebanese pound', symbol: 'ل.ل'),
    CurrencyItem(code: 'LKR', name: 'Sri Lankan rupee', symbol: 'Rs'),
    CurrencyItem(code: 'LRD', name: 'Liberian dollar', symbol: 'L\$'),
    CurrencyItem(code: 'LSL', name: 'Lesotho loti', symbol: 'M'),
    CurrencyItem(code: 'LYD', name: 'Libyan dinar', symbol: 'ل.د'),
    CurrencyItem(code: 'MAD', name: 'Moroccan dirham', symbol: 'د.م.'),
    CurrencyItem(code: 'MDL', name: 'Moldovan leu', symbol: 'L'),
    CurrencyItem(code: 'MGA', name: 'Malagasy ariary', symbol: 'Ar'),
    CurrencyItem(code: 'MKD', name: 'Macedonian denar', symbol: 'ден'),
    CurrencyItem(code: 'MMK', name: 'Myanmar kyat', symbol: 'K'),
    CurrencyItem(code: 'MNT', name: 'Mongolian tögrög', symbol: '₮'),
    CurrencyItem(code: 'MOP', name: 'Macanese pataca', symbol: 'MOP\$'),
    CurrencyItem(code: 'MRU', name: 'Mauritanian ouguiya', symbol: 'UM'),
    CurrencyItem(code: 'MUR', name: 'Mauritian rupee', symbol: '₨'),
    CurrencyItem(code: 'MVR', name: 'Maldivian rufiyaa', symbol: 'Rf'),
    CurrencyItem(code: 'MWK', name: 'Malawian kwacha', symbol: 'MK'),
    CurrencyItem(code: 'MXN', name: 'Mexican peso', symbol: 'Mex\$'),
    CurrencyItem(code: 'MYR', name: 'Malaysian ringgit', symbol: 'RM'),
    CurrencyItem(code: 'MZN', name: 'Mozambican metical', symbol: 'MT'),
    CurrencyItem(code: 'NAD', name: 'Namibian dollar', symbol: 'N\$'),
    CurrencyItem(code: 'NGN', name: 'Nigerian naira', symbol: '₦'),
    CurrencyItem(code: 'NIO', name: 'Nicaraguan córdoba', symbol: 'C\$'),
    CurrencyItem(code: 'NOK', name: 'Norwegian krone', symbol: 'kr'),
    CurrencyItem(code: 'NPR', name: 'Nepalese rupee', symbol: '₨'),
    CurrencyItem(code: 'NZD', name: 'New Zealand dollar', symbol: 'NZ\$'),
    CurrencyItem(code: 'OMR', name: 'Omani rial', symbol: 'ر.ع.'),
    CurrencyItem(code: 'PAB', name: 'Panamanian balboa', symbol: 'B/.'),
    CurrencyItem(code: 'PEN', name: 'Peruvian sol', symbol: 'S/.'),
    CurrencyItem(code: 'PGK', name: 'Papua New Guinean kina', symbol: 'K'),
    CurrencyItem(code: 'PHP', name: 'Philippine peso', symbol: '₱'),
    CurrencyItem(code: 'PKR', name: 'Pakistani rupee', symbol: '₨'),
    CurrencyItem(code: 'PLN', name: 'Polish złoty', symbol: 'zł'),
    CurrencyItem(code: 'PYG', name: 'Paraguayan guaraní', symbol: '₲'),
    CurrencyItem(code: 'QAR', name: 'Qatari riyal', symbol: 'ر.ق'),
    CurrencyItem(code: 'RON', name: 'Romanian leu', symbol: 'lei'),
    CurrencyItem(code: 'RSD', name: 'Serbian dinar', symbol: 'дин.'),
    CurrencyItem(code: 'RUB', name: 'Russian ruble', symbol: '₽'),
    CurrencyItem(code: 'RWF', name: 'Rwandan franc', symbol: 'FRw'),
    CurrencyItem(code: 'SAR', name: 'Saudi riyal', symbol: 'ر.س'),
    CurrencyItem(code: 'SBD', name: 'Solomon Islands dollar', symbol: 'SI\$'),
    CurrencyItem(code: 'SCR', name: 'Seychelles rupee', symbol: 'SR'),
    CurrencyItem(code: 'SDG', name: 'Sudanese pound', symbol: 'ج.س.'),
    CurrencyItem(code: 'SEK', name: 'Swedish krona', symbol: 'kr'),
    CurrencyItem(code: 'SGD', name: 'Singapore dollar', symbol: 'S\$'),
    CurrencyItem(code: 'SHP', name: 'Saint Helena pound', symbol: '£'),
    CurrencyItem(code: 'SLE', name: 'Sierra Leonean leone', symbol: 'Le'),
    CurrencyItem(code: 'SOS', name: 'Somali shilling', symbol: 'Sh.So.'),
    CurrencyItem(code: 'SRD', name: 'Surinamese dollar', symbol: 'Sr\$'),
    CurrencyItem(code: 'SSP', name: 'South Sudanese pound', symbol: 'SS£'),
    CurrencyItem(code: 'STN', name: 'São Tomé and Príncipe dobra', symbol: 'Db'),
    CurrencyItem(code: 'SVC', name: 'Salvadoran colón', symbol: '₡'),
    CurrencyItem(code: 'SYP', name: 'Syrian pound', symbol: '£S'),
    CurrencyItem(code: 'SZL', name: 'Swazi lilangeni', symbol: 'L'),
    CurrencyItem(code: 'THB', name: 'Thai baht', symbol: '฿'),
    CurrencyItem(code: 'TJS', name: 'Tajikistani somoni', symbol: 'ЅМ'),
    CurrencyItem(code: 'TMT', name: 'Turkmenistan manat', symbol: 'T'),
    CurrencyItem(code: 'TND', name: 'Tunisian dinar', symbol: 'د.ت'),
    CurrencyItem(code: 'TOP', name: 'Tongan paʻanga', symbol: 'T\$'),
    CurrencyItem(code: 'TRY', name: 'Turkish lira', symbol: '₺'),
    CurrencyItem(code: 'TTD', name: 'Trinidad and Tobago dollar', symbol: 'TT\$'),
    CurrencyItem(code: 'TWD', name: 'New Taiwan dollar', symbol: 'NT\$'),
    CurrencyItem(code: 'TZS', name: 'Tanzanian shilling', symbol: 'TSh'),
    CurrencyItem(code: 'UAH', name: 'Ukrainian hryvnia', symbol: '₴'),
    CurrencyItem(code: 'UGX', name: 'Ugandan shilling', symbol: 'USh'),
    CurrencyItem(code: 'USD', name: 'United States dollar', symbol: '\$'),
    CurrencyItem(code: 'UYU', name: 'Uruguayan peso', symbol: '\$U'),
    CurrencyItem(code: 'UZS', name: 'Uzbekistani sum', symbol: 'soʻm'),
    CurrencyItem(code: 'VED', name: 'Venezuelan digital bolívar', symbol: 'Bs.D'),
    CurrencyItem(code: 'VES', name: 'Venezuelan bolívar', symbol: 'Bs.S'),
    CurrencyItem(code: 'VND', name: 'Vietnamese đồng', symbol: '₫'),
    CurrencyItem(code: 'VUV', name: 'Vanuatu vatu', symbol: 'VT'),
    CurrencyItem(code: 'WST', name: 'Samoan tala', symbol: 'WS\$'),
    CurrencyItem(code: 'XAF', name: 'Central African CFA franc', symbol: 'FCFA'),
    CurrencyItem(code: 'XCD', name: 'East Caribbean dollar', symbol: 'EC\$'),
    CurrencyItem(code: 'XCG', name: 'Caribbean guilder', symbol: 'Cg'),
    CurrencyItem(code: 'XOF', name: 'West African CFA franc', symbol: 'CFA'),
    CurrencyItem(code: 'XPF', name: 'CFP franc', symbol: '₣'),
    CurrencyItem(code: 'YER', name: 'Yemeni rial', symbol: '﷼'),
    CurrencyItem(code: 'ZAR', name: 'South African rand', symbol: 'R'),
    CurrencyItem(code: 'ZMW', name: 'Zambian kwacha', symbol: 'ZK'),
    CurrencyItem(code: 'ZWG', name: 'Zimbabwe Gold', symbol: 'ZiG'),
  ];

  /// Find a CurrencyItem by its 3-letter code, with fallback to defaultCurrency.
  static CurrencyItem find(String? code) {
    if (code == null || code.trim().isEmpty) return defaultCurrency;
    final normalized = code.trim().toUpperCase();
    for (final item in currencies) {
      if (item.code == normalized) {
        return item;
      }
    }
    // Handle cases where code was formatted as "INR (₹)" or similar
    final extracted = RegExp(r'[A-Za-z]{3}').firstMatch(normalized)?.group(0);
    if (extracted != null) {
      for (final item in currencies) {
        if (item.code == extracted) {
          return item;
        }
      }
    }
    return defaultCurrency;
  }

  /// Get symbol by currency code.
  static String getSymbol(String? code) => find(code).symbol;

  /// Get currency name by currency code.
  static String getName(String? code) => find(code).name;

  /// Get formatted display string e.g. "INR (₹)".
  static String getFormattedCode(String? code) => find(code).formattedCode;
}
