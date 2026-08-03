
class ModuleModel {
  int? id;
  String? moduleName;
  String? moduleType;
  String? thumbnailFullUrl;
  String? iconFullUrl;
  int? themeId;
  String? description;
  int? storesCount;
  String? createdAt;
  String? updatedAt;
  List<ModuleZoneData>? zones;

  /// Future backend terminology override for module-aware headers (e.g. "Restaurants",
  /// "Grocery Stores", "Pharmacies"). NULL today → `ModuleTerminology` falls back to a
  /// deterministic moduleType+moduleName label. Never hardcoded, never invented.
  String? providerLabelPlural;

  /// Scheduled availability (Glovo-style). These are **adapter fields** for the
  /// future Admin → Module Schedule backend — all NULL today, so every module
  /// stays [ModuleAvailability.enabled]. When the backend sends them,
  /// `resolveModuleAvailability` fades + disables a module outside its window
  /// with NO frontend architecture change. Never hardcoded, never invented.
  /// See docs/BACKEND_INTEGRATION_QUEUE.md item 19.
  String? openTime;      // 'HH:mm' or 'HH:mm:ss'
  String? closeTime;     // 'HH:mm' or 'HH:mm:ss'
  String? timezone;      // IANA name, e.g. 'Africa/Lagos' (display/contract only)
  bool? temporaryClose;  // manual "closed now" override
  bool? holidayToday;    // holiday-override flag for today

  ModuleModel({
    this.id,
    this.moduleName,
    this.moduleType,
    this.thumbnailFullUrl,
    this.storesCount,
    this.iconFullUrl,
    this.themeId,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.zones,
    this.openTime,
    this.closeTime,
    this.timezone,
    this.temporaryClose,
    this.holidayToday,
  });

  ModuleModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    moduleName = json['module_name'];
    moduleType = json['module_type'];
    thumbnailFullUrl = json['thumbnail_full_url'];
    iconFullUrl = json['icon_full_url'];
    themeId = json['theme_id'];
    description = json['description'];
    storesCount = json['stores_count'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    if (json['zones'] != null) {
      zones = <ModuleZoneData>[];
      json['zones'].forEach((v) => zones!.add(ModuleZoneData.fromJson(v)));
    }
    // Adapter field — absent today (null), populated when the backend ships it.
    providerLabelPlural = json['provider_label_plural'];
    // Adapter fields — absent today (null), populated when the backend ships them.
    openTime = json['open_time'];
    closeTime = json['close_time'];
    timezone = json['timezone'];
    temporaryClose = json['temporary_close'] is bool
        ? json['temporary_close']
        : (json['temporary_close'] == 1 || json['temporary_close'] == '1');
    holidayToday = json['holiday_today'] is bool
        ? json['holiday_today']
        : (json['holiday_today'] == 1 || json['holiday_today'] == '1');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['module_name'] = moduleName;
    data['module_type'] = moduleType;
    data['thumbnail_full_url'] = thumbnailFullUrl;
    data['icon_full_url'] = iconFullUrl;
    data['theme_id'] = themeId;
    data['description'] = description;
    data['stores_count'] = storesCount;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    if (zones != null) {
      data['zones'] = zones!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ModuleZoneData {
  int? id;
  String? name;
  int? status;
  String? createdAt;
  String? updatedAt;
  bool? cashOnDelivery;
  bool? digitalPayment;

  ModuleZoneData({
    this.id,
    this.name,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.cashOnDelivery,
    this.digitalPayment,
  });

  ModuleZoneData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    cashOnDelivery = json['cash_on_delivery'];
    digitalPayment = json['digital_payment'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['cash_on_delivery'] = cashOnDelivery;
    data['digital_payment'] = digitalPayment;
    return data;
  }
}
