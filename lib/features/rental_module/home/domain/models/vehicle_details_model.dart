class VehicleModel {
  int? id;
  String? name;
  String? description;
  String? thumbnail;
  String? images;
  int? providerId;
  int? brandId;
  int? categoryId;
  String? model;
  String? type;
  String? engineCapacity;
  String? enginePower;
  String? seatingCapacity;
  bool? airCondition;
  String? fuelType;
  String? transmissionType;
  int? multipleVehicles;
  bool? tripHourly;
  bool? tripDistance;
  bool? tripDayWise;
  double? hourlyPrice;
  double? distancePrice;
  double? dayWisePrice;
  String? discountType;
  double? discountPrice;
  String? tag;
  String? documents;
  int? status;
  int? newTag;
  int? totalTrip;
  double? avgRating;
  int? totalReviews;
  String? createdAt;
  String? updatedAt;
  int? zoneId;
  int? vehicleIdentitiesCount;
  int? totalVehicles;
  String? thumbnailFullUrl;
  List<String>? imagesFullUrl;
  List<String>? documentsFullUrl;
  Brand? brand;
  Provider? provider;
  RentalFlashSale? flashSale;

  VehicleModel(
      {this.id,
        this.name,
        this.description,
        this.thumbnail,
        this.images,
        this.providerId,
        this.brandId,
        this.categoryId,
        this.model,
        this.type,
        this.engineCapacity,
        this.enginePower,
        this.seatingCapacity,
        this.airCondition,
        this.fuelType,
        this.transmissionType,
        this.multipleVehicles,
        this.tripHourly,
        this.tripDistance,
        this.tripDayWise,
        this.hourlyPrice,
        this.distancePrice,
        this.dayWisePrice,
        this.discountType,
        this.discountPrice,
        this.tag,
        this.documents,
        this.status,
        this.newTag,
        this.totalTrip,
        this.avgRating,
        this.totalReviews,
        this.createdAt,
        this.updatedAt,
        this.zoneId,
        this.vehicleIdentitiesCount,
        this.totalVehicles,
        this.thumbnailFullUrl,
        this.imagesFullUrl,
        this.documentsFullUrl,
        this.brand,
        this.provider,
        this.flashSale,
      });

  VehicleModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    thumbnail = json['thumbnail'];
    images = json['images'];
    providerId = json['provider_id'];
    brandId = json['brand_id'];
    categoryId = json['category_id'];
    model = json['model'];
    type = json['type'];
    engineCapacity = json['engine_capacity'];
    enginePower = json['engine_power'];
    seatingCapacity = json['seating_capacity'];
    airCondition = json['air_condition'].toString() == '1';
    fuelType = json['fuel_type'];
    transmissionType = json['transmission_type'];
    multipleVehicles = json['multiple_vehicles'];
    tripHourly = json['trip_hourly'].toString() == '1';
    tripDistance = json['trip_distance'].toString() == '1';
    tripDayWise = json['trip_day_wise'].toString() == '1';
    hourlyPrice = json['hourly_price']?.toDouble();
    distancePrice = json['distance_price']?.toDouble();
    dayWisePrice = json['day_wise_price']?.toDouble();
    discountType = json['discount_type'];
    discountPrice = json['discount_price']?.toDouble();
    tag = json['tag'];
    documents = json['documents'];
    status = json['status'];
    newTag = json['new_tag'];
    totalTrip = json['total_trip'];
    // avgRating = json['avg_rating']?.toDouble();
    avgRating = json['avg_rating'] != null ? double.parse(json['avg_rating'].toString()) : 0;
    totalReviews = json['total_reviews'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    zoneId = json['zone_id'];
    // BUGFIX: `get-vehicle-details` serialises `total_vehicles` as a **string**
    // (`"total_vehicles": "1"`) while the list endpoints send integers. The raw
    // assignment threw `type 'String' is not a subtype of type 'int?'`, aborting
    // `fromJson` — so `vehicleDetailsModel` stayed null and the Vehicle Details page
    // hung on its loading state forever. Parsed defensively (same resolution as
    // `TaxiVendorModel`): number or numeric string both work, absent stays null.
    vehicleIdentitiesCount = _asInt(json['total_vehicle_count']);
    totalVehicles = _asInt(json['total_vehicles']);
    thumbnailFullUrl = json['thumbnail_full_url'];
    imagesFullUrl = json['images_full_url'].cast<String>();
    if (json['documents_full_url'] != null) {
      documentsFullUrl = <String>[];
      json['documents_full_url'].forEach((v) {
        if(v != null) {
          documentsFullUrl!.add(v);
        }
      });
    }
    brand = json['brand'] != null ? Brand.fromJson(json['brand']) : null;
    provider = json['provider'] != null
        ? Provider.fromJson(json['provider'])
        : null;
    // Rental Flash Sale is appended to every vehicle by the backend (null when no
    // active/eligible campaign). Parsed defensively so existing vehicle parsing is
    // never affected when it is null. The frontend renders backend values only.
    flashSale = json['flash_sale'] != null ? RentalFlashSale.fromJson(json['flash_sale']) : null;
  }

  /// Tolerates the backend sending an integer counter as a numeric string.
  /// Returns null for null/unparseable input — never a fabricated default.
  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    data['thumbnail'] = thumbnail;
    data['images'] = images;
    data['provider_id'] = providerId;
    data['brand_id'] = brandId;
    data['category_id'] = categoryId;
    data['model'] = model;
    data['type'] = type;
    data['engine_capacity'] = engineCapacity;
    data['engine_power'] = enginePower;
    data['seating_capacity'] = seatingCapacity;
    data['air_condition'] = airCondition;
    data['fuel_type'] = fuelType;
    data['transmission_type'] = transmissionType;
    data['multiple_vehicles'] = multipleVehicles;
    data['trip_hourly'] = tripHourly;
    data['trip_distance'] = tripDistance;
    data['trip_day_wise'] = tripDayWise;
    data['hourly_price'] = hourlyPrice;
    data['distance_price'] = distancePrice;
    data['day_wise_price'] = dayWisePrice;
    data['discount_type'] = discountType;
    data['discount_price'] = discountPrice;
    data['tag'] = tag;
    data['documents'] = documents;
    data['status'] = status;
    data['new_tag'] = newTag;
    data['total_trip'] = totalTrip;
    data['avg_rating'] = avgRating;
    data['total_reviews'] = totalReviews;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['zone_id'] = zoneId;
    data['total_vehicle_count'] = vehicleIdentitiesCount;
    data['total_vehicles'] = totalVehicles;
    data['thumbnail_full_url'] = thumbnailFullUrl;
    data['images_full_url'] = imagesFullUrl;
    if (documentsFullUrl != null) {
      data['documents_full_url'] = documentsFullUrl!.map((v) => v).toList();
    }
    if (brand != null) {
      data['brand'] = brand!.toJson();
    }
    if (provider != null) {
      data['provider'] = provider!.toJson();
    }
    if (flashSale != null) {
      data['flash_sale'] = flashSale!.toJson();
    }
    return data;
  }

  // ── Rental Flash Sale pricing (Rental-level, not vehicle-specific) ──
  // These resolve pricing by a rentalType STRING key, so every Rental type
  // resolves the same way: Car Rental uses 'hourly' | 'day_wise' |
  // 'distance_wise'; a future Short Apt Rental type maps its own rate key(s)
  // through the same entry points with no rewrite. The frontend NEVER computes
  // flash pricing — it uses the backend-authoritative `flash_price` verbatim.

  /// The original (pre-flash) per-unit rate for [rentalType]. Falls back to the
  /// distance rate for any non-hourly / non-day type.
  double baseRate(String? rentalType) {
    if (rentalType == 'hourly') return hourlyPrice ?? 0;
    if (rentalType == 'day_wise') return dayWisePrice ?? 0;
    return distancePrice ?? 0;
  }

  /// The applicable per-unit rate for [rentalType]: the backend Flash Sale
  /// price when an active percent campaign targets that axis, otherwise the
  /// original rate. Amount / booking_total campaigns publish no per-unit flash
  /// price, so the original rate is returned unchanged (their discount applies
  /// at the total level and is never invented here).
  double applicableRate(String? rentalType) {
    final RentalFlashAxisPrice? axis = flashSale?.axisPrice(_flashAxisKey(rentalType));
    if (axis != null && axis.hasFlashPrice) {
      return axis.flashPrice!;
    }
    return baseRate(rentalType);
  }

  /// Whether a per-unit Flash Sale rate applies to [rentalType].
  bool hasFlashRate(String? rentalType) {
    final RentalFlashAxisPrice? axis = flashSale?.axisPrice(_flashAxisKey(rentalType));
    return axis != null && axis.hasFlashPrice;
  }

  /// Maps a booking rentalType to its Flash Sale axis key. The distance branch
  /// is the default, so 'distance' and 'distance_wise' both resolve correctly.
  static String _flashAxisKey(String? rentalType) {
    if (rentalType == 'hourly') return 'hourly';
    if (rentalType == 'day_wise') return 'day_wise';
    return 'distance_wise';
  }
}

/// Rental Flash Sale — read-only presentation of the backend's authoritative
/// `flash_sale` payload appended to each vehicle. The frontend NEVER computes
/// flash pricing; it renders backend values and shows nothing when null.
class RentalFlashSale {
  final String? title;
  final String? discountType;       // 'percent' | 'amount'
  final double? discount;
  final String? discountAppliesTo;  // 'unit_price' | 'booking_total'
  final String? appliesTo;          // 'all' | 'hourly' | 'distance_wise' | 'day_wise'
  final String? startDate;
  final String? endDate;
  final RentalFlashPrices? prices;

  RentalFlashSale({this.title, this.discountType, this.discount, this.discountAppliesTo,
    this.appliesTo, this.startDate, this.endDate, this.prices});

  RentalFlashSale.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        discountType = json['discount_type'],
        discount = json['discount'] != null ? double.tryParse(json['discount'].toString()) : null,
        discountAppliesTo = json['discount_applies_to'],
        appliesTo = json['applies_to'],
        startDate = json['start_date'],
        endDate = json['end_date'],
        prices = json['prices'] != null ? RentalFlashPrices.fromJson(json['prices']) : null;

  Map<String, dynamic> toJson() => {
        'title': title,
        'discount_type': discountType,
        'discount': discount,
        'discount_applies_to': discountAppliesTo,
        'applies_to': appliesTo,
        'start_date': startDate,
        'end_date': endDate,
        'prices': prices?.toJson(),
      };

  /// Amount campaigns apply to the booking total and publish no per-unit flash
  /// price, so the UI must NOT fabricate one.
  bool get isBookingTotal => discountAppliesTo == 'booking_total';

  /// The backend axis price for [axisKey] ('hourly' | 'distance_wise' | 'day_wise'),
  /// or null when the campaign does not apply to that axis.
  RentalFlashAxisPrice? axisPrice(String axisKey) {
    switch (axisKey) {
      case 'hourly':
        return prices?.hourly;
      case 'distance_wise':
        return prices?.distanceWise;
      case 'day_wise':
        return prices?.dayWise;
    }
    return null;
  }
}

class RentalFlashPrices {
  final RentalFlashAxisPrice? hourly;
  final RentalFlashAxisPrice? distanceWise;
  final RentalFlashAxisPrice? dayWise;

  RentalFlashPrices({this.hourly, this.distanceWise, this.dayWise});

  RentalFlashPrices.fromJson(Map<String, dynamic> json)
      : hourly = json['hourly'] != null ? RentalFlashAxisPrice.fromJson(json['hourly']) : null,
        distanceWise = json['distance_wise'] != null ? RentalFlashAxisPrice.fromJson(json['distance_wise']) : null,
        dayWise = json['day_wise'] != null ? RentalFlashAxisPrice.fromJson(json['day_wise']) : null;

  Map<String, dynamic> toJson() => {
        'hourly': hourly?.toJson(),
        'distance_wise': distanceWise?.toJson(),
        'day_wise': dayWise?.toJson(),
      };
}

class RentalFlashAxisPrice {
  final double? originalPrice;
  final double? flashPrice;      // null for amount / booking_total campaigns
  final double? discountAmount;  // null for amount / booking_total campaigns

  RentalFlashAxisPrice({this.originalPrice, this.flashPrice, this.discountAmount});

  RentalFlashAxisPrice.fromJson(Map<String, dynamic> json)
      : originalPrice = json['original_price'] != null ? double.tryParse(json['original_price'].toString()) : null,
        flashPrice = json['flash_price'] != null ? double.tryParse(json['flash_price'].toString()) : null,
        discountAmount = json['discount_amount'] != null ? double.tryParse(json['discount_amount'].toString()) : null;

  Map<String, dynamic> toJson() => {
        'original_price': originalPrice,
        'flash_price': flashPrice,
        'discount_amount': discountAmount,
      };

  /// A usable per-unit flash price exists only when the backend supplied a
  /// non-null flash_price (percent campaigns).
  bool get hasFlashPrice => flashPrice != null;
}

class Brand {
  int? id;
  String? name;
  String? image;
  String? imageFullUrl;

  Brand({this.id, this.name, this.image, this.imageFullUrl});

  Brand.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    image = json['image'];
    imageFullUrl = json['image_full_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['image'] = image;
    data['image_full_url'] = imageFullUrl;
    return data;
  }
}

class Provider {
  int? id;
  String? name;
  String? logo;
  String? coverPhoto;
  List<int>? rating;
  double? avgRating;
  int? ratingCount;
  bool? gstStatus;
  String? gstCode;
  String? logoFullUrl;
  String? coverPhotoFullUrl;
  String? metaImageFullUrl;
  Discount? discount;
  List<Translations>? translations;
  List<Storage>? storage;

  Provider(
      {this.id,
        this.name,
        this.logo,
        this.coverPhoto,
        this.rating,
        this.avgRating,
        this.ratingCount,
        this.gstStatus,
        this.gstCode,
        this.logoFullUrl,
        this.coverPhotoFullUrl,
        this.metaImageFullUrl,
        this.discount,
        this.translations,
        this.storage});

  Provider.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    logo = json['logo'];
    coverPhoto = json['cover_photo'];
    // rating = json['rating'];
    if(json['rating'] != null) {
      rating = [];
      json['rating'].forEach((v) {
        rating!.add(v);
      });
    }
    avgRating = json['avg_rating']?.toDouble();
    ratingCount = json['rating_count'];
    gstStatus = json['gst_status'];
    gstCode = json['gst_code'];
    logoFullUrl = json['logo_full_url'];
    coverPhotoFullUrl = json['cover_photo_full_url'];
    metaImageFullUrl = json['meta_image_full_url'];
    discount = json['discount'] != null ? Discount.fromJson(json['discount']) : null;
    if (json['translations'] != null) {
      translations = <Translations>[];
      json['translations'].forEach((v) {
        translations!.add(Translations.fromJson(v));
      });
    }
    if (json['storage'] != null) {
      storage = <Storage>[];
      json['storage'].forEach((v) {
        storage!.add(Storage.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['logo'] = logo;
    data['cover_photo'] = coverPhoto;
    data['rating'] = rating;
    data['avg_rating'] = avgRating;
    data['rating_count'] = ratingCount;
    data['gst_status'] = gstStatus;
    data['gst_code'] = gstCode;
    data['logo_full_url'] = logoFullUrl;
    data['cover_photo_full_url'] = coverPhotoFullUrl;
    data['meta_image_full_url'] = metaImageFullUrl;
    if (discount != null) {
      data['discount'] = discount!.toJson();
    }
    if (translations != null) {
      data['translations'] = translations!.map((v) => v.toJson()).toList();
    }
    if (storage != null) {
      data['storage'] = storage!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Discount {
  int? id;
  String? startDate;
  String? endDate;
  String? startTime;
  String? endTime;
  double? minPurchase;
  double? maxDiscount;
  double? discount;
  String? discountType;
  int? storeId;
  String? createdAt;
  String? updatedAt;

  Discount({this.id, this.startDate, this.endDate, this.startTime, this.endTime, this.minPurchase, this.maxDiscount, this.discount, this.discountType, this.storeId, this.createdAt, this.updatedAt});

  Discount.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    startDate = json['start_date'];
    endDate = json['end_date'];
    startTime = json['start_time'];
    endTime = json['end_time'];
    minPurchase = json['min_purchase']?.toDouble();
    maxDiscount = json['max_discount']?.toDouble();
    discount = json['discount']?.toDouble();
    discountType = json['discount_type'];
    storeId = json['store_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['start_date'] = startDate;
    data['end_date'] = endDate;
    data['start_time'] = startTime;
    data['end_time'] = endTime;
    data['min_purchase'] = minPurchase;
    data['max_discount'] = maxDiscount;
    data['discount'] = discount;
    data['discount_type'] = discountType;
    data['store_id'] = storeId;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class Translations {
  int? id;
  String? translationableType;
  int? translationableId;
  String? locale;
  String? key;
  String? value;
  String? createdAt;
  String? updatedAt;

  Translations(
      {this.id,
        this.translationableType,
        this.translationableId,
        this.locale,
        this.key,
        this.value,
        this.createdAt,
        this.updatedAt});

  Translations.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    translationableType = json['translationable_type'];
    translationableId = json['translationable_id'];
    locale = json['locale'];
    key = json['key'];
    value = json['value'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['translationable_type'] = translationableType;
    data['translationable_id'] = translationableId;
    data['locale'] = locale;
    data['key'] = key;
    data['value'] = value;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class Storage {
  int? id;
  String? dataType;
  String? dataId;
  String? key;
  String? value;
  String? createdAt;
  String? updatedAt;

  Storage(
      {this.id,
        this.dataType,
        this.dataId,
        this.key,
        this.value,
        this.createdAt,
        this.updatedAt});

  Storage.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    dataType = json['data_type'];
    dataId = json['data_id'];
    key = json['key'];
    value = json['value'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['data_type'] = dataType;
    data['data_id'] = dataId;
    data['key'] = key;
    data['value'] = value;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}