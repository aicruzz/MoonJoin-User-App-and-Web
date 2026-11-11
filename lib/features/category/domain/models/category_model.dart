import 'package:moonjoin/helper/image_variant_helper.dart';
class CategoryModel {
  int? id;
  String? name;
  String? imageFullUrl;
  /// Slice 3: additive `image_variants` (read-only, never serialised). Null keeps [imageFullUrl] as the only URL.
  Map<String, String>? imageVariants;

  CategoryModel({this.id, this.name, this.imageFullUrl});

  CategoryModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    imageFullUrl = json['image_full_url'];
    imageVariants = parseImageVariants(json['image_variants']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['image_full_url'] = imageFullUrl;
    return data;
  }
}
