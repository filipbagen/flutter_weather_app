class OutfitData {
  final String? top;
  final String? bottom;
  final String? shoes;
  final String? accessory;

  OutfitData({this.top, this.bottom, this.shoes, this.accessory});

  factory OutfitData.fromJson(Map<String, dynamic> json) {
    return OutfitData(
      top: json['top'],
      bottom: json['bottom'],
      shoes: json['shoes'],
      accessory: json['accessory'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'top': top,
      'bottom': bottom,
      'shoes': shoes,
      'accessory': accessory,
    };
  }
}
