class CreatePortfolioItemRequest {
  final String title;
  final String? description;
  final String? externalUrl;
  final String sourceType; // 'direct_upload', 'instagram', 'youtube'
  final Map<String, dynamic>? metrics;
  final bool isCollaborative;
  
  final String? thumbnailUrl;
  final String? mediaUrl;
  
  final String? temporaryThumbnailUrl;
  final String? temporaryMediaUrl;

  CreatePortfolioItemRequest({
    required this.title,
    this.description,
    this.externalUrl,
    required this.sourceType,
    required this.isCollaborative,
    this.metrics,
    this.thumbnailUrl,
    this.mediaUrl,
    this.temporaryThumbnailUrl,
    this.temporaryMediaUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'external_url': externalUrl,
      'source_type': sourceType,
      'is_collaborative': isCollaborative,
      if (metrics != null) 'metrics': metrics,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (mediaUrl != null) 'media_url': mediaUrl,
      if (temporaryThumbnailUrl != null) 'temporary_thumbnail_url': temporaryThumbnailUrl,
      if (temporaryMediaUrl != null) 'temporary_media_url': temporaryMediaUrl,
    }.removeNulls();
  }
}

extension MapExtensions on Map<String, dynamic> {
  Map<String, dynamic> removeNulls() {
    return Map.fromEntries(entries.where((e) => e.value != null));
  }
}