class FirebaseImage {
  final String name;
  final String downloadUrl;
  final String fullPath;
  final int? sizeBytes;
  final DateTime? timeCreated;
  final DateTime? updated;
  final Map<String, dynamic>? metadata;

  const FirebaseImage({
    required this.name,
    required this.downloadUrl,
    required this.fullPath,
    this.sizeBytes,
    this.timeCreated,
    this.updated,
    this.metadata,
  });

  factory FirebaseImage.fromJson(Map<String, dynamic> json) {
    return FirebaseImage(
      name: json['name'] as String,
      downloadUrl: json['downloadUrl'] as String,
      fullPath: json['fullPath'] as String,
      sizeBytes: json['sizeBytes'] as int?,
      timeCreated: json['timeCreated'] != null
          ? DateTime.parse(json['timeCreated'] as String)
          : null,
      updated: json['updated'] != null
          ? DateTime.parse(json['updated'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'downloadUrl': downloadUrl,
      'fullPath': fullPath,
      'sizeBytes': sizeBytes,
      'timeCreated': timeCreated?.toIso8601String(),
      'updated': updated?.toIso8601String(),
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'FirebaseImage(name: $name, downloadUrl: $downloadUrl, fullPath: $fullPath)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FirebaseImage &&
        other.name == name &&
        other.downloadUrl == downloadUrl &&
        other.fullPath == fullPath;
  }

  @override
  int get hashCode {
    return name.hashCode ^ downloadUrl.hashCode ^ fullPath.hashCode;
  }
}