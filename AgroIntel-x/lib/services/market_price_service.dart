import 'dart:convert';
import 'package:http/http.dart' as http;

class MarketPriceService {
  static const String _apiKey =
      '579b464db66ec23bdd000001b24549dc888248206e2b81910ef09819';
  static const String _resourceId = '9ef84268-d588-465a-a308-a864a43d0070';


  /// Fetch last [limit] market price records for the given filters.
  Future<List<MarketPrice>> getMarketPrices({
    required String state,
    required String district,
    required String commodity,
    String? arrivalDate,
    int limit = 10,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'api-key': _apiKey,
        'format': 'json',
        'filters[state]': state,
        'filters[district]': district,
        'filters[commodity]': commodity,
        'limit': limit.toString(),
      };

      if (arrivalDate != null && arrivalDate.isNotEmpty) {
        queryParams['filters[arrival_date]'] = arrivalDate;
      }

      // Using Uri.https ensures cleaner encoding of keys like filters[state]
      final uri = Uri.https(
        'api.data.gov.in',
        '/resource/$_resourceId',
        queryParams,
      );

      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'User-Agent':
                  'PostmanRuntime/7.32.3', // Mimic Postman to avoid blocking
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> records = data['records'] ?? [];
        return records.map((r) => MarketPrice.fromJson(r)).toList();
      } else {
        throw Exception('API Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
}

// ─── Model ───────────────────────────────────────────────────────────────────

class MarketPrice {
  final String state;
  final String district;
  final String market;
  final String commodity;
  final String variety;
  final String arrivalDate;
  final double minPrice;
  final double maxPrice;
  final double modalPrice;

  MarketPrice({
    required this.state,
    required this.district,
    required this.market,
    required this.commodity,
    required this.variety,
    required this.arrivalDate,
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
  });

  factory MarketPrice.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString().replaceAll(',', '')) ?? 0;
    }

    return MarketPrice(
      state: json['state']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      market: json['market']?.toString() ?? '',
      commodity: json['commodity']?.toString() ?? '',
      variety: json['variety']?.toString() ?? '',
      arrivalDate: json['arrival_date']?.toString() ?? '',
      minPrice: parsePrice(json['min_price']),
      maxPrice: parsePrice(json['max_price']),
      modalPrice: parsePrice(json['modal_price']),
    );
  }
}

// ─── Static Data Lists ────────────────────────────────────────────────────────

class MarketPriceData {
  static const List<String> states = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Delhi',
  ];

  static const Map<String, List<String>> districtsByState = {
    'Maharashtra': [
      'Pune',
      'Mumbai',
      'Nashik',
      'Nagpur',
      'Aurangabad',
      'Solapur',
      'Satara',
      'Kolhapur',
      'Sangli',
      'Ahmednagar',
      'Latur',
      'Nanded',
      'Jalgaon',
      'Dhule',
      'Amravati',
    ],
    'Gujarat': [
      'Ahmedabad',
      'Surat',
      'Vadodara',
      'Rajkot',
      'Anand',
      'Gandhinagar',
      'Mehsana',
      'Junagadh',
      'Bhavnagar',
      'Kutch',
    ],
    'Uttar Pradesh': [
      'Lucknow',
      'Agra',
      'Kanpur',
      'Varanasi',
      'Allahabad',
      'Meerut',
      'Farrukhabad',
      'Bareilly',
      'Mathura',
      'Aligarh',
    ],
    'Madhya Pradesh': [
      'Bhopal',
      'Indore',
      'Gwalior',
      'Jabalpur',
      'Ujjain',
      'Sehore',
      'Hoshangabad',
      'Dewas',
      'Ratlam',
      'Mandsaur',
    ],
    'Karnataka': [
      'Bangalore',
      'Mysore',
      'Hubli',
      'Belgaum',
      'Bijapur',
      'Kolar',
      'Tumkur',
      'Hassan',
      'Dharwad',
      'Koppal',
    ],
    'Rajasthan': [
      'Jaipur',
      'Jodhpur',
      'Ajmer',
      'Kota',
      'Udaipur',
      'Alwar',
      'Sikar',
      'Nagaur',
      'Bikaner',
      'Barmer',
    ],
    'Punjab': [
      'Amritsar',
      'Ludhiana',
      'Jalandhar',
      'Patiala',
      'Bathinda',
      'Moga',
      'Ferozepur',
      'Fazilka',
      'Hoshiarpur',
      'Gurdaspur',
    ],
    'Haryana': [
      'Gurugram',
      'Faridabad',
      'Hisar',
      'Rohtak',
      'Panipat',
      'Karnal',
      'Sirsa',
      'Yamunanagar',
      'Ambala',
      'Bhiwani',
    ],
    'Andhra Pradesh': [
      'Guntur',
      'Kurnool',
      'Visakhapatnam',
      'Krishna',
      'Nellore',
      'Prakasam',
      'Chittoor',
      'East Godavari',
      'West Godavari',
      'Anantapur',
    ],
    'Tamil Nadu': [
      'Chennai',
      'Coimbatore',
      'Madurai',
      'Tiruchirappalli',
      'Salem',
      'Dindigul',
      'Vellore',
      'Erode',
      'Tirunelveli',
      'Virudhunagar',
    ],
    'West Bengal': [
      'Kolkata',
      'Howrah',
      'Burdwan',
      'Midnapore',
      'Malda',
      'Nadia',
      'Hooghly',
      'Murshidabad',
      'Bankura',
      'Purulia',
    ],
    'Bihar': [
      'Patna',
      'Nalanda',
      'Gaya',
      'Muzaffarpur',
      'Bhagalpur',
      'Vaishali',
      'Darbhanga',
      'Samastipur',
      'Madhubani',
      'Begusarai',
    ],
    'Delhi': [
      'New Delhi',
      'North Delhi',
      'South Delhi',
      'East Delhi',
      'West Delhi',
    ],
    'Telangana': [
      'Hyderabad',
      'Warangal',
      'Karimnagar',
      'Nizamabad',
      'Khammam',
      'Adilabad',
      'Rangareddy',
      'Medak',
      'Mahbubnagar',
      'Nalgonda',
    ],
  };

  static List<String> getDistricts(String state) {
    return districtsByState[state] ?? ['Select District'];
  }

  static const List<Map<String, String>> commodities = [
    {'name': 'Onion', 'emoji': '🧅'},
    {'name': 'Tomato', 'emoji': '🍅'},
    {'name': 'Potato', 'emoji': '🥔'},
    {'name': 'Wheat', 'emoji': '🌾'},
    {'name': 'Rice', 'emoji': '🍚'},
    {'name': 'Maize', 'emoji': '🌽'},
    {'name': 'Garlic', 'emoji': '🧄'},
    {'name': 'Ginger', 'emoji': '🫚'},
    {'name': 'Soyabean', 'emoji': '🫘'},
    {'name': 'Groundnut', 'emoji': '🥜'},
    {'name': 'Cotton', 'emoji': '🌿'},
    {'name': 'Sugarcane', 'emoji': '🍬'},
    {'name': 'Turmeric', 'emoji': '🟡'},
    {'name': 'Chilli', 'emoji': '🌶️'},
    {'name': 'Banana', 'emoji': '🍌'},
    {'name': 'Mango', 'emoji': '🥭'},
    {'name': 'Grapes', 'emoji': '🍇'},
    {'name': 'Pomegranate', 'emoji': '🍎'},
    {'name': 'Bajra', 'emoji': '🌾'},
    {'name': 'Jowar', 'emoji': '🌾'},
    {'name': 'Arhar/Tur', 'emoji': '🫘'},
    {'name': 'Moong', 'emoji': '🫘'},
    {'name': 'Urad', 'emoji': '🫘'},
    {'name': 'Lemon', 'emoji': '🍋'},
    {'name': 'Cabbage', 'emoji': '🥬'},
    {'name': 'Cauliflower', 'emoji': '🥦'},
    {'name': 'Brinjal', 'emoji': '🍆'},
    {'name': 'Bhindi(Ladies Finger)', 'emoji': '🟢'},
    {'name': 'Peas Wet', 'emoji': '🫛'},
    {'name': 'Drumstick', 'emoji': '🟤'},
  ];
}
