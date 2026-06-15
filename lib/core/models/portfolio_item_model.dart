enum PortfolioSourceType { directUpload, instagram, youtube }
enum PortfolioStatus { processing, active, failed }

class PortfolioItem {
  final String id;
  final String title;
  final String? description;
  final PortfolioStatus status;
  final PortfolioSourceType sourceType;
  final bool isCollaborative;
  final String? externalUrl;
  final String? externalThumbnailUrl;
  final String? externalEmbedUrl;
  final String? thumbnailUrl;
  final String? mediaUrl;
  final Map<String, dynamic> metrics;
  final Map<String, dynamic> temporaryAssets;

  PortfolioItem({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.sourceType,
    required this.isCollaborative,
    this.externalUrl,
    this.externalThumbnailUrl,
    this.externalEmbedUrl,
    this.mediaUrl,
    this.thumbnailUrl,
    required this.metrics,
    required this.temporaryAssets,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: _parseStatus(json['status'] as String),
      sourceType: _parseSourceType(json['source_type'] as String),
      isCollaborative: json['is_collaborative'] as bool? ?? false,
      externalUrl: json['external_url'] as String?,
      externalThumbnailUrl: json['external_thumbnail_url'] as String?,
      externalEmbedUrl: json['external_embed_url'] as String?,
      metrics: (json['metrics'] as Map<String, dynamic>?) ?? {},
      temporaryAssets: (json['temporary_assets'] as Map<String, dynamic>?) ?? {},
      thumbnailUrl: json['thumbnail_url'],
      mediaUrl: json['media_url']
    );
  }

  static PortfolioStatus _parseStatus(String status) {
    switch (status) {
      case 'processing': return PortfolioStatus.processing;
      case 'active': return PortfolioStatus.active;
      default: return PortfolioStatus.failed;
    }
  }

  static PortfolioSourceType _parseSourceType(String type) {
    switch (type) {
      case 'instagram': return PortfolioSourceType.instagram;
      case 'youtube': return PortfolioSourceType.youtube;
      default: return PortfolioSourceType.directUpload;
    }
  }
}