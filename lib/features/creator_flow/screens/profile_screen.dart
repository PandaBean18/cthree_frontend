import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cthree/core/models/profile_model.dart';
import 'package:cthree/core/api/profile_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cthree/features/creator_flow/progress_arc_painter.dart';
import 'package:cthree/core/app_video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cthree/core/models/portfolio_item_model.dart';
import 'package:cthree/data/dto/create_portfolio_item_request.dart';
import 'package:cthree/data/dto/create_platform_request.dart';
import 'package:cthree/core/models/creator_platform_model.dart';
import 'dart:io';

class CreatorProfileScreen extends StatefulWidget {
  const CreatorProfileScreen({super.key});

  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  final ProfileRepository _profileRepo = ProfileRepository();
  ProfileModel? _profile;
  bool _isLoading = true;

  double _profileUploadProgress = 0.0;
  bool _isProfileUploading = false;
  final ImagePicker _picker = ImagePicker();

  double _sampleWorkUploadProgress = 0.0;
  bool _isSampleWorkUploading = false;
  final ImagePicker _sampleWorkPicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final data = await _profileRepo.getMe();

    if (mounted) {
      setState(() {
        _profile = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary,),),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Could not load profile", style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
              TextButton(onPressed: _loadProfile, child: Text("Retry", style: TextStyle(backgroundColor: Theme.of(context).colorScheme.primary, color: Theme.of(context).colorScheme.onPrimary),))
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        color: Theme.of(context).colorScheme.secondary,
        child: CustomScrollView(
          physics: BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              floating: true,
              leading: BackButton(color: Colors.white,),
              actions: [
                IconButton(onPressed: null, icon: Icon(Icons.share_outlined, color: Colors.white,)),
                IconButton(onPressed: null, icon: Icon(Icons.more_vert, color: Colors.white))
              ],
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildAvatar(_profile!.avatarUrl),
                  SizedBox(height: 20,),
                  Text(_profile!.username,
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    child: Text(
                      _profile!.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF6F7685))
                    ),
                  ),
                  _buildConnectButton(),
                  const SizedBox(height: 32,)
                ],
              ),
            ),

            _buildConnectedPlatforms(),
            SliverToBoxAdapter(child: _buildBrandCollaborationsSection()),
            SliverToBoxAdapter(child: _buildSampleWorkSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }



  Future<void> _handleProfileImageUpload() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    
    if (image == null) return;

    _profileRepo.updateProfilePicture(image).listen(
      (progress) {
        setState(() {
          _isProfileUploading = true;
          _profileUploadProgress = progress;
        });

        if (progress >= 1.0) {
          Future.delayed(const Duration(milliseconds: 500), () {
            setState(() {
              _isProfileUploading = false;
              _profileUploadProgress = 0;
            });
            _loadProfile();
          });
        }
      },
      onError: (e) {
        setState(() {
          _isProfileUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e")),
        );
      }
    );
  }

  Widget _buildSampleWorkSection() {
    final portfolio = _profile?.portfolio ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            'SAMPLE WORK', 
            style: TextStyle(color: Color(0xFF6F7685), fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 24),
            itemCount: portfolio.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildAddMediaButton();
              }

              final item = portfolio[index-1];
              return _buildMediaThumbnail(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddMediaButton() {
    return GestureDetector(
      onTap: _isSampleWorkUploading ? null : () => _showUnifiedAddMediaForm(context),      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3), width: 1),
        ),
        child: Center(
          child: _isSampleWorkUploading 
            ? CircularProgressIndicator(
              value: _sampleWorkUploadProgress,
              color: Theme.of(context).colorScheme.secondary,
            )
            : Icon(Icons.add_rounded, color: Theme.of(context).primaryColor, size: 40),
        ),
      ),
    );
  }

  void _showUnifiedAddMediaForm(BuildContext context) {
    final TextEditingController linkController = TextEditingController();
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    final TextEditingController brandController = TextEditingController();
    final TextEditingController viewsController = TextEditingController();
    final TextEditingController likesController = TextEditingController();
    final TextEditingController commentsController = TextEditingController();
    
    bool isParsing = false;
    bool isSubmitting = false;
    bool isCollab = false;
    bool isUploadingThumbnail = false;
    
    Map<String, dynamic>? parsedData;
    String? thumbnailUrl;
    String? thumbnailItemId;
    XFile? localThumbnail;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: const Color(0xFF12151C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    left: 24,
                    right: 24,
                    top: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Add to Portfolio", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      const Text("External URL (Optional)", style: TextStyle(color: Color(0xFF6F7685), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: linkController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _getInputDecoration("e.g., YouTube or Instagram link"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: isParsing ? null : () async {
                              final url = linkController.text.trim();
                              if (url.isEmpty) return;
                              setModalState(() => isParsing = true);
                              final data = await _profileRepo.parseLink(url);
                              if (data != null) {
                                setModalState(() {
                                  parsedData = data;
                                  if (titleController.text.isEmpty) titleController.text = data['title'] ?? '';
                                  if (descController.text.isEmpty) descController.text = data['description'] ?? '';
                                  
                                  if (data['metrics'] != null) {
                                    final m = data['metrics'];
                                    viewsController.text = m['views']?.toString() ?? '';
                                    likesController.text = m['likes']?.toString() ?? '';
                                    commentsController.text = m['comments']?.toString() ?? '';
                                  }
                                  
                                  if (thumbnailUrl == null && localThumbnail == null) {
                                    thumbnailUrl = data['temporary_thumbnail_url'] ?? data['thumbnail_url'];
                                  }
                                  isParsing = false;
                                });
                              } else {
                                setModalState(() => isParsing = false);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to parse link.")));
                              }
                            },
                            child: isParsing 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("Fetch", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      const Text("Thumbnail (Optional)", style: TextStyle(color: Color(0xFF6F7685), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            height: 100,
                            width: 140,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E222A),
                              borderRadius: BorderRadius.circular(12),
                              image: localThumbnail != null 
                                ? DecorationImage(image: FileImage(File(localThumbnail!.path)), fit: BoxFit.cover)
                                : (thumbnailUrl != null 
                                    ? DecorationImage(image: NetworkImage(thumbnailUrl!), fit: BoxFit.cover)
                                    : null)
                            ),
                            child: (localThumbnail == null && thumbnailUrl == null)
                                ? const Center(child: Icon(Icons.image, color: Color(0xFF6F7685), size: 36))
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isUploadingThumbnail ? null : () async {
                                final XFile? image = await _sampleWorkPicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                                if (image != null) {
                                  setModalState(() => isUploadingThumbnail = true);
                                  final uploadedData = await _profileRepo.uploadThumbnail(image);
                                  setModalState(() {
                                    isUploadingThumbnail = false;
                                    if (uploadedData != null) {
                                      thumbnailItemId = uploadedData['id'];
                                      thumbnailUrl = uploadedData['url'];
                                      localThumbnail = image;
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to upload thumbnail")));
                                    }
                                  });
                                }
                              },
                              icon: isUploadingThumbnail 
                                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : Icon(Icons.upload, color: Theme.of(context).primaryColor, size: 20),
                              label: const Text("Upload Custom", style: TextStyle(color: Colors.white)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Theme.of(context).primaryColor),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            )
                          )
                        ],
                      ),
                      const SizedBox(height: 24),

                      const Text("Title *", style: TextStyle(color: Color(0xFF6F7685), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _getInputDecoration("Title"),
                      ),
                      const SizedBox(height: 16),

                      const Text("Description", style: TextStyle(color: Color(0xFF6F7685), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: _getInputDecoration("Description"),
                      ),
                      const SizedBox(height: 24),
                      
                      const Text("Metrics", style: TextStyle(color: Color(0xFF6F7685), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: viewsController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: _getInputDecoration("Views").copyWith(prefixIcon: const Icon(Icons.visibility, color: Color(0xFF6F7685), size: 18)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: likesController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: _getInputDecoration("Likes").copyWith(prefixIcon: const Icon(Icons.favorite, color: Color(0xFF6F7685), size: 18)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: commentsController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: _getInputDecoration("Comments").copyWith(prefixIcon: const Icon(Icons.comment, color: Color(0xFF6F7685), size: 18)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Leave metrics blank to attempt fetching from the platform. Note: some platforms like Instagram do not support this.",
                        style: TextStyle(color: Color(0xFF6F7685), fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 24),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Was this a collaboration?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        activeColor: Theme.of(context).primaryColor,
                        value: isCollab,
                        onChanged: (val) {
                          setModalState(() => isCollab = val);
                        },
                      ),
                      if (isCollab) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: brandController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _getInputDecoration("Brand Name (e.g., Nike)"),
                        ),
                      ],
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: isSubmitting ? null : () async {
                            if (titleController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Title is required.")));
                              return;
                            }
                            setModalState(() => isSubmitting = true);
                            try {
                              final extUrl = linkController.text.trim();
                              final sourceType = (extUrl.contains('youtube') || extUrl.contains('youtu.be')) 
                                  ? 'youtube' 
                                  : (extUrl.contains('instagram') ? 'instagram' : 'manual');

                              String finalDesc = descController.text.trim();
                              if (isCollab && brandController.text.isNotEmpty) {
                                finalDesc += "\n\nCollaboration with: ${brandController.text.trim()}";
                              }

                              Map<String, dynamic>? metricsPayload;
                              if (viewsController.text.isNotEmpty || likesController.text.isNotEmpty || commentsController.text.isNotEmpty) {
                                metricsPayload = {
                                  'views': int.tryParse(viewsController.text) ?? 0,
                                  'likes': int.tryParse(likesController.text) ?? 0,
                                  'comments': int.tryParse(commentsController.text) ?? 0,
                                };
                              }

                              final request = CreatePortfolioItemRequest(
                                title: titleController.text.trim(),
                                description: finalDesc.isEmpty ? null : finalDesc,
                                externalUrl: extUrl.isEmpty ? null : extUrl,
                                sourceType: sourceType,
                                isCollaborative: isCollab,
                                metrics: metricsPayload,
                                thumbnailUrl: thumbnailUrl,
                                thumbnailItemId: thumbnailItemId,
                              );

                              final newItem = await _profileRepo.createPortfolioItem(request);
                              if (context.mounted && newItem != null) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Successfully added to portfolio!")),
                                );
                                _loadProfile();
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                                );
                              }
                            } finally {
                              setModalState(() => isSubmitting = false);
                            }
                          },
                          child: isSubmitting
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("Confirm & Add to Portfolio", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        );
      }
    );
  }

  InputDecoration _getInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF6F7685)),
      filled: true,
      fillColor: const Color(0xFF1E222A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

 Widget _buildMediaPreviewBox(String label, String? url, {required bool isVideo}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF6F7685), fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            if (url != null) {
              _showExpandedMedia(url, isVideo ? 'video' : 'image');
            }
          },
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF1E222A),
              borderRadius: BorderRadius.circular(12),
              image: (url != null && !isVideo) 
                ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
                : null,
            ),
            child: Center(
              child: url == null
                  ? const Text("Unavailable", style: TextStyle(color: Color(0xFF6F7685), fontWeight: FontWeight.w600))
                  : isVideo 
                      ? const Icon(Icons.play_circle_fill, color: Colors.white, size: 36)
                      : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6F7685), size: 18),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
 
  Widget _buildMediaThumbnail(PortfolioItem item) {
    final int views = item.metrics['views'] ?? 0;
    final int likes = item.metrics['likes'] ?? 0;

    return GestureDetector(
      onTap: () => _showExpandedMediaSampleWork(item),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      image: item.thumbnailUrl != null 
                        ? DecorationImage(
                            image: NetworkImage(item.thumbnailUrl!),
                            fit: BoxFit.cover
                          )
                        : null,
                    ),
                    child: Center(
                      child: item.thumbnailUrl == null
                        ? const Text("Processing", style: TextStyle(color: Color(0xFF6F7685), fontSize: 12))
                        : const Icon(Icons.play_circle_fill, color: Colors.white, size: 36),
                    ),
                  ),
                  
                  if (item.isCollaborative)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.6),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        ),
                        child: const Icon(Icons.handshake, color: Colors.white, size: 12),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.visibility, color: Color(0xFF6F7685), size: 14),
                const SizedBox(width: 4),
                Text(_formatNumber(views), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                const Spacer(),
                const Icon(Icons.favorite, color: Color(0xFF6F7685), size: 14),
                const SizedBox(width: 4),
                Text(_formatNumber(likes), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _extractYoutubeId(String data) {
    try {
      if (data.contains('<iframe')) {
        final RegExp srcRegex = RegExp(r'src="([^"]+)"');
        final match = srcRegex.firstMatch(data);
        if (match != null && match.groupCount >= 1) {
          final srcUrl = match.group(1)!;
          return YoutubePlayer.convertUrlToId(srcUrl);
        }
      }
      return YoutubePlayer.convertUrlToId(data);
    } catch (e) {
      print("Failed to extract YouTube ID: $e");
      return null;
    }
  }

  void _showExpandedMediaSampleWork(PortfolioItem item) {
    final bool isYouTube = item.sourceType == PortfolioSourceType.youtube ||
        (item.externalUrl?.contains('youtube') ?? false) ||
        (item.externalUrl?.contains('youtu.be') ?? false);

    String? ytVideoId;
    if (isYouTube && item.externalUrl != null) {
      ytVideoId = YoutubePlayer.convertUrlToId(item.externalUrl!);
    }

    final String mediaToPlay = item.mediaUrl ?? item.externalUrl ?? '';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: isYouTube && ytVideoId != null
                  ? YoutubePlayer(
                      controller: YoutubePlayerController(
                        initialVideoId: ytVideoId,
                        flags: const YoutubePlayerFlags(
                          autoPlay: true,
                          mute: false,
                        ),
                      ),
                      showVideoProgressIndicator: true,
                      progressColors: ProgressBarColors(
                        playedColor: Theme.of(context).primaryColor,
                        handleColor: Theme.of(context).colorScheme.secondary,
                      ),
                    )
                  : AppVideoPlayer(url: mediaToPlay),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            )
          ],
        ),
      )
    );
  }

  void _showExpandedMedia(String urlOrIframe, String mediaType) {
    final bool isYouTube = mediaType == 'video' && 
        (urlOrIframe.contains('youtube') || urlOrIframe.contains('youtu.be') || urlOrIframe.contains('<iframe'));
        
    final String? ytVideoId = isYouTube ? _extractYoutubeId(urlOrIframe) : null;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Center(
                child: mediaType == 'image'
                    ? InteractiveViewer(
                        child: Image.network(urlOrIframe, fit: BoxFit.contain),
                      )
                    : isYouTube && ytVideoId != null
                        ? YoutubePlayer(
                            controller: YoutubePlayerController(
                              initialVideoId: ytVideoId,
                              flags: const YoutubePlayerFlags(
                                autoPlay: true,
                                mute: false,
                                hideControls: false,
                              ),
                            ),
                            showVideoProgressIndicator: true,
                            progressColors: ProgressBarColors(
                              playedColor: Theme.of(context).primaryColor,
                              handleColor: Theme.of(context).colorScheme.secondary,
                            ),
                          )
                        : AppVideoPlayer(url: urlOrIframe),
              ),
              
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 24),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildAvatar(String? url) {
    return GestureDetector(
      onTap: _isProfileUploading ? null : _handleProfileImageUpload,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isProfileUploading) 
            SizedBox(
              height: 130,
              width: 130,
              child: CustomPaint(
                painter: ProgressArcPainter(progress: _profileUploadProgress, color: Theme.of(context).colorScheme.secondary),
              ),
            ),
          
          CircleAvatar(
            radius: 60,
            backgroundColor: Color(0xFFFFD59E),
            backgroundImage: url != null ? NetworkImage(url) : null,
            child: url == null && ! _isProfileUploading
              ? const Icon(Icons.person, size: 80, color: Color(0xFF4A2B29))
              : null,
          ),

          if (_isProfileUploading)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  "${(_profileUploadProgress * 100).toInt()}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20
                  ),
                ),
              ),
            ),
          
          // Positioned(
          //   bottom: 0,
          //   right: 0,
          //   child: Container(
          //     padding: const EdgeInsets.all(4),
          //     decoration: BoxDecoration(
          //       color: Theme.of(context).primaryColor, 
          //       shape: BoxShape.circle,
          //       border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
          //     ),
          //     child: const Icon(Icons.check, color: Colors.white, size: 16),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildConnectButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Theme.of(context).colorScheme.surface),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.transparent
        ),
        onPressed: _showConnectPlatformModal,
        icon: Icon(Icons.link, color: Theme.of(context).primaryColor, size: 20),
        label: const Text(
          "Connect Accounts",
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)
        ),
      ),
    );
  }

  void _showAddBrandModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddBrandModal(),
    ).then((_) {
      _loadProfile();
    });
  }

  Widget _buildBrandCollaborationsSection() {
    final brands = _profile?.brandCollaborations ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BRANDS WORKED WITH',
                style: TextStyle(color: Color(0xFF6F7685), fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: _showAddBrandModal,
              )
            ],
          ),
        ),
        if (brands.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('No brands added yet.', style: TextStyle(color: Colors.white54)),
          )
        else
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: brands.length,
              itemBuilder: (context, index) {
                final brand = brands[index];
                return Container(
                  width: 250,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (brand.logoUrl != null && brand.logoUrl!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                brand.logoUrl!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (c,e,s) => const Icon(Icons.business, color: Colors.white),
                              ),
                            )
                          else
                            const Icon(Icons.business, color: Colors.white, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              brand.companyName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (brand.description != null && brand.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            brand.description!,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildConnectedPlatforms() {
    if (_profile == null || _profile!.creatorPlatforms.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text("CONNECTED PLATFORMS", style: TextStyle(color: Color(0xFF6F7685), letterSpacing: 1.2, fontWeight: FontWeight.bold)),
              );
            }
            final platform = _profile!.creatorPlatforms[index - 1];
            return _buildPlatformCard(platform);
          },
          childCount: _profile!.creatorPlatforms.length + 1,
        ),
      ),
    );
  }

  Widget _buildPlatformCard(CreatorPlatformModel platform) {
    FaIconData icon;
    Color iconColor;
    
    final nameLower = platform.name.toLowerCase();
    if (nameLower.contains('instagram') || nameLower.contains('ig')) {
      icon = FontAwesomeIcons.instagram;
      iconColor = Theme.of(context).colorScheme.secondary;
    } else if (nameLower.contains('youtube') || nameLower.contains('yt')) {
      icon = FontAwesomeIcons.youtube;
      iconColor = Theme.of(context).primaryColor;
    } else if (nameLower.contains('tiktok')) {
      icon = FontAwesomeIcons.tiktok;
      iconColor = Colors.white;
    } else {
      icon = FontAwesomeIcons.link;
      iconColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () {
        if (platform.insights.isNotEmpty) {
          _showExpandedMedia(platform.insights.first, 'image');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16)
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: FaIcon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16,),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    platform.name, 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "@${platform.username}", 
                    style: const TextStyle(color: Color(0xFF6F7685), fontSize: 12)
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (platform.followers != null)
                  Text(
                    _formatNumber(platform.followers!), 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                if (platform.engagementRate != null)
                  Text(
                    "${platform.engagementRate}% ER", 
                    style: TextStyle(color: iconColor, fontSize: 12, fontWeight: FontWeight.bold)
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showConnectPlatformModal() {
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final erController = TextEditingController();
    final followersController = TextEditingController();
    final viewsController = TextEditingController();
    List<XFile> selectedInsights = [];
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF12151C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    left: 24,
                    right: 24,
                    top: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Connect Platform", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      const Text("Platform Name", style: TextStyle(color: Color(0xFF6F7685), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _getInputDecoration("e.g. Instagram, YouTube, TikTok"),
                      ),
                      const SizedBox(height: 16),

                      const Text("Username", style: TextStyle(color: Color(0xFF6F7685), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: usernameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _getInputDecoration("e.g. @username"),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Followers", style: TextStyle(color: Color(0xFF6F7685), fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: followersController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _getInputDecoration("e.g. 15000"),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Avg Views", style: TextStyle(color: Color(0xFF6F7685), fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: viewsController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _getInputDecoration("e.g. 5000"),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      const Text("Engagement Rate (%)", style: TextStyle(color: Color(0xFF6F7685), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: erController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white),
                        decoration: _getInputDecoration("e.g. 5.5"),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Tip: Calculate your engagement rate by taking the average (likes + comments) of your last 7-10 posts, divided by your total followers, then multiplied by 100.",
                        style: TextStyle(color: Color(0xFF6F7685), fontSize: 10, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 24),

                      const Text("Upload Insights (Screenshots)", style: TextStyle(color: Color(0xFF6F7685), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final List<XFile> images = await _sampleWorkPicker.pickMultiImage(imageQuality: 80);
                          if (images.isNotEmpty) {
                            setModalState(() {
                              selectedInsights.addAll(images);
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            border: Border.all(color: Theme.of(context).colorScheme.surface),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: selectedInsights.isEmpty 
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate, color: Color(0xFF6F7685), size: 32),
                                    SizedBox(height: 8),
                                    Text("Tap to select multiple screenshots", style: TextStyle(color: Color(0xFF6F7685), fontSize: 12)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.all(8),
                                itemCount: selectedInsights.length,
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        width: 80,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          image: DecorationImage(
                                            image: FileImage(File(selectedInsights[index].path)),
                                            fit: BoxFit.cover,
                                          )
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 12,
                                        child: GestureDetector(
                                          onTap: () {
                                            setModalState(() {
                                              selectedInsights.removeAt(index);
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: isSubmitting ? null : () async {
                            final name = nameController.text.trim();
                            final username = usernameController.text.trim();
                            if (name.isEmpty || username.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name and Username are required")));
                              return;
                            }

                            setModalState(() => isSubmitting = true);
                            
                            List<String> insightIds = [];
                            for (var image in selectedInsights) {
                              final id = await _profileRepo.uploadInsight(image);
                              if (id != null) {
                                insightIds.add(id);
                              }
                            }

                            final request = CreatePlatformRequest(
                              name: name,
                              username: username,
                              engagementRate: double.tryParse(erController.text.trim()),
                              followers: int.tryParse(followersController.text.trim()),
                              views: int.tryParse(viewsController.text.trim()),
                              insightItemIds: insightIds,
                            );

                            final newPlatform = await _profileRepo.createCreatorPlatform(request);
                            if (newPlatform != null) {
                              Navigator.pop(context);
                              _loadProfile(); 
                            } else {
                              setModalState(() => isSubmitting = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to connect platform")));
                              }
                            }
                          },
                          child: isSubmitting 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Save Platform", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          }
        );
      }
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000000) return '${(number / 1000000000).toStringAsFixed(1)}B';
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }
}

class _AddBrandModal extends StatefulWidget {
  const _AddBrandModal();

  @override
  State<_AddBrandModal> createState() => _AddBrandModalState();
}

class _AddBrandModalState extends State<_AddBrandModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _postUrlCtrl = TextEditingController();

  String? _logoUrl;
  bool _isLoading = false;
  bool _isSearchingLogo = false;
  String? _logoError;

  InputDecoration _getInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF6F7685)),
      filled: true,
      fillColor: const Color(0xFF1E222A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _searchLogo() {
    String url = _urlCtrl.text.trim();
    if (url.isEmpty) return;

    url = url.replaceAll(RegExp(r'^https?://'), '').split('/').first;

    setState(() {
      _isSearchingLogo = true;
      _logoError = null;
      _logoUrl = null;
    });

    final testUrl = 'https://logos.hunter.io/$url';

    final image = NetworkImage(testUrl);
    final stream = image.resolve(const ImageConfiguration());
    stream.addListener(ImageStreamListener(
      (info, synchronousCall) {
        if (mounted) {
          setState(() {
            _logoUrl = testUrl;
            _isSearchingLogo = false;
          });
        }
      },
      onError: (exception, stackTrace) {
        if (mounted) {
          setState(() {
            _logoError = "Logo not found. We'll just show the brand name.";
            _isSearchingLogo = false;
          });
        }
      },
    ));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ProfileRepository();
      final res = await repo.addBrandCollaboration(
        companyName: _nameCtrl.text.trim(),
        companyUrl: _urlCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        postUrl: _postUrlCtrl.text.trim(),
        logoUrl: _logoUrl,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (res != null) {
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to add brand.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1F26),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: mq.viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Add Brand Collaboration", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 16),
              const Text("Company Name", style: TextStyle(color: Color(0xFF6F7685), fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _getInputDecoration("e.g. Nike, Adidas, Apple"),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              const Text("Company URL", style: TextStyle(color: Color(0xFF6F7685), fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _urlCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _getInputDecoration("e.g. nike.com"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSearchingLogo ? null : _searchLogo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: _isSearchingLogo
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.search, color: Colors.white),
                    ),
                  )
                ],
              ),
              if (_logoUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      const Text('Logo Preview: ', style: TextStyle(color: Colors.white54)),
                      const SizedBox(width: 8),
                      Image.network(_logoUrl!, width: 40, height: 40, fit: BoxFit.cover),
                    ],
                  ),
                ),
              if (_logoError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(_logoError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                ),
              const SizedBox(height: 16),
              const Text("Description", style: TextStyle(color: Color(0xFF6F7685), fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: _getInputDecoration("What did you do?"),
              ),
              const SizedBox(height: 16),
              const Text("Post/Video URL (Optional)", style: TextStyle(color: Color(0xFF6F7685), fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _postUrlCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _getInputDecoration("e.g. https://instagram.com/p/..."),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Brand', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}