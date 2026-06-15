import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:chart_sparkline/chart_sparkline.dart';
import 'package:cthree/core/models/profile_model.dart';
import 'package:cthree/core/api/profile_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cthree/features/creator_flow/progress_arc_painter.dart';
import 'package:cthree/core/app_video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cthree/core/models/portfolio_item_model.dart';
import 'package:cthree/data/dto/create_portfolio_item_request.dart';
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

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.6,
                children: [
                  _buildStatCard('1.2M', 'FOLLOWERS'),
                  _buildStatCard('8.5%', 'ENG. RATE'),
                ],
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const Text("CHANNELS", style: TextStyle(color: Color(0xFF6F7685), letterSpacing: 1.2)),
                  const SizedBox(height: 16,),
                  _buildChannelCard(FontAwesomeIcons.instagram, "Instagram", "@${_profile!.username}", [2, 3, 2, 5, 4, 7], "45k", "+2.4%", Theme.of(context).colorScheme.secondary),
                  _buildChannelCard(FontAwesomeIcons.youtube, "YouTube", "@${_profile!.username}.vlogs", [5, 4, 6, 5, 8, 7], "1.5M", "+5.1%", Theme.of(context).primaryColor)
                ]),
              ),
            ),
            SliverToBoxAdapter(child: _buildSampleWorkSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSampleWorkUpload() async {
    final XFile? media = await _sampleWorkPicker.pickMedia(
      imageQuality: 80,
    );

    if (media == null) return;

    final path = media.path.toLowerCase();
    final isVideo = path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.mkv') || path.endsWith('.avi');

    if (mounted) {
      _showUploadMediaReviewModal(context, media, isVideo);
    }
  }

  void _executeMediaUpload({
    required XFile mediaFile,
    required String title,
    required String description,
    required bool isCollaborative,
    String? collabBrand,
    String? externalUrl,
  }) {
    _profileRepo.uploadSampleWork(
      mediaFile: mediaFile, 
      title: title, 
      description: description, 
      isCollaborative: isCollaborative, 
      collabBrand: collabBrand, 
      externalUrl: externalUrl).listen(
      (progress) {
        setState(() {
          _isSampleWorkUploading = true;
          _sampleWorkUploadProgress = progress;
        });

        if (progress >= 1.0) {
          Future.delayed(const Duration(milliseconds: 500), () {
            setState(() {
              _isSampleWorkUploading = false;
              _sampleWorkUploadProgress = 0;
            });
            _loadProfile();
          });
        }
      },
      onError: (e) {
        setState(() {
          _isSampleWorkUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e")),
        );
      }
    );
  }

  Widget _buildLocalMediaPreviewBox(XFile media, {required bool isVideo}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Selected Media", style: TextStyle(color: Color(0xFF6F7685), fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1E222A),
            borderRadius: BorderRadius.circular(12),
            image: !isVideo
              ? DecorationImage(image: FileImage(File(media.path)), fit: BoxFit.cover)
              : null,
          ),
          child: Center(
            child: isVideo
                ? const Icon(Icons.play_circle_fill, color: Colors.white, size: 48)
                : null,
          ),
        ),
      ],
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
      onTap: _isSampleWorkUploading ? null : () => _showAddMediaOptions(context),      child: Container(
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

  void _showAddMediaOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12151C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E222A),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.link, color: Theme.of(context).primaryColor, size: 20),
                ),
                title: const Text('Paste link (Instagram, YouTube)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _showPasteLinkModal(context);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E222A),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.upload_file, color: Theme.of(context).primaryColor, size: 20),
                ),
                title: const Text('Upload media', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _handleSampleWorkUpload();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPasteLinkModal(BuildContext context) {
    final TextEditingController linkController = TextEditingController();
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    final TextEditingController brandController = TextEditingController();
    
    bool isParsing = false;
    bool isSubmitting = false;
    bool isCollab = false;
    Map<String, dynamic>? parsedData;

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
            
            if (parsedData == null) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 24,
                  right: 24,
                  top: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Add Sample Work",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: linkController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Paste Instagram or YouTube URL",
                        hintStyle: const TextStyle(color: Color(0xFF6F7685)),
                        filled: true,
                        fillColor: const Color(0xFF1E222A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isParsing
                            ? null
                            : () async {
                                final url = linkController.text.trim();
                                if (url.isEmpty) return;

                                setModalState(() => isParsing = true);
                                
                                final data = await _profileRepo.parseLink(url);
                                
                                if (data != null) {
                                  setModalState(() {
                                    parsedData = data;
                                    titleController.text = data['title'] ?? '';
                                    descController.text = data['description'] ?? '';
                                    isParsing = false;
                                  });
                                } else {
                                  setModalState(() => isParsing = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Failed to parse link.")),
                                    );
                                  }
                                }
                              },
                        child: isParsing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text("Fetch Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            }

            final metrics = parsedData!['metrics'] ?? {};
            final thumbUrl = parsedData!['temporary_thumbnail_url'] ?? (parsedData!['thumbnail_url']);
            final mediaUrl = parsedData!['temporary_media_url'] ?? parsedData!['media_url'];

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
                          const Text("Review Details", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(child: _buildMediaPreviewBox("Thumbnail", thumbUrl, isVideo: false)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildMediaPreviewBox("Video", mediaUrl, isVideo: true)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      const Text("Title", style: TextStyle(color: Color(0xFF6F7685), fontSize: 12, fontWeight: FontWeight.bold)),
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

                      if (metrics.isNotEmpty) ...[
                        const Text("Performance Metrics", style: TextStyle(color: Color(0xFF6F7685), fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMetricItem(Icons.visibility, metrics['views']?.toString() ?? '0'),
                            _buildMetricItem(Icons.favorite, metrics['likes']?.toString() ?? '0'),
                            _buildMetricItem(Icons.comment, metrics['comments']?.toString() ?? '0'),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

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
                          onPressed: isSubmitting 
                            ? null 
                            : () async {
                                setModalState(() => isSubmitting = true);

                                try {
                                  final externalUrl = parsedData!['external_url']?.toString() ?? '';
                                  final sourceType = externalUrl.contains('youtube') || externalUrl.contains('youtu.be') 
                                      ? 'youtube' 
                                      : 'instagram';

                                
                                  String finalDesc = descController.text.trim();
                                  if (isCollab && brandController.text.isNotEmpty) {
                                    finalDesc += "\n\nCollaboration with: ${brandController.text.trim()}";
                                  }

                                  final request = CreatePortfolioItemRequest(
                                    title: titleController.text.trim(),
                                    description: finalDesc,
                                    externalUrl: externalUrl,
                                    sourceType: sourceType,
                                    isCollaborative: isCollab,
                                    metrics: parsedData!['metrics'],
                                    thumbnailUrl: sourceType == 'youtube' ? parsedData!['thumbnail_url'] : null,
                                    mediaUrl: sourceType == 'youtube' ? parsedData!['media_url'] : null,
                                    temporaryThumbnailUrl: sourceType == 'instagram' ? parsedData!['temporary_thumbnail_url'] : null,
                                    temporaryMediaUrl: sourceType == 'instagram' ? parsedData!['temporary_media_url'] : null,
                                  );

                                  final newItem = await _profileRepo.createPortfolioItem(request);

                                  if (context.mounted && newItem != null) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Successfully added to portfolio!")),
                                    );
                                    
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
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text("Confirm & Add to Portfolio", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showUploadMediaReviewModal(BuildContext context, XFile media, bool isVideo) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    final TextEditingController brandController = TextEditingController();
    final TextEditingController externalUrlController = TextEditingController();
    
    bool isCollab = false;

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
                          const Text("Review Upload", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildLocalMediaPreviewBox(media, isVideo: isVideo),
                      const SizedBox(height: 24),

                      const Text("Title *", style: TextStyle(color: Color(0xFF6F7685), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _getInputDecoration("Title"),
                      ),
                      const SizedBox(height: 16),

                      const Text("Description *", style: TextStyle(color: Color(0xFF6F7685), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: _getInputDecoration("Description"),
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
                        const SizedBox(height: 24),
                      ],

                      const Text("External URL (Optional)", style: TextStyle(color: Color(0xFF6F7685), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: externalUrlController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _getInputDecoration("e.g., Link to live post"),
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            print("Direct Upload confirmed.");
                            print("Title: ${titleController.text}");
                            print("Desc: ${descController.text}");
                            print("URL: ${externalUrlController.text}");
                            
                            Navigator.pop(context);
                            _executeMediaUpload(
                              mediaFile: media,
                              title: titleController.text,
                              description: descController.text,
                              isCollaborative: isCollab,
                              collabBrand: brandController.text,
                              externalUrl: externalUrlController.text,
                            );
                          },
                          child: const Text("Confirm & Upload", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
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
        onPressed: () {
          print("Connect accounts button");
        },
        icon: Icon(Icons.link, color: Theme.of(context).primaryColor, size: 20,),
        label: const Text(
          "Connect Accounts",
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),),
          Text(label, style: const TextStyle(color: Color(0xFF6F7685), fontSize: 12))
        ],
      ),
    );
  }

  Widget _buildChannelCard(
    IconData icon, 
    String title,
    String handle,
    List<double> data,
    String count, 
    String trend, 
    Color trendColor
  ) {
    return Container(
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
            child: FaIcon(icon, color: trendColor, size: 20),
          ),
          const SizedBox(width: 16,),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  handle, 
                  style: TextStyle(color: Color(0xFF6F7685), fontSize: 12)
                ),
              ],
            ),
          ),

          SizedBox(
            width: 60,
            height: 30,
            child: Sparkline(
              data: data,
              lineColor: trendColor,
              lineWidth: 2,
              fillMode: FillMode.none,
            ),
          ), 

          const SizedBox(width: 16,),

          Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              count, 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Text(
              trend, 
              style: TextStyle(
                color: trendColor.withValues(alpha: 0.8), 
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        ],
      )
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000000) return '${(number / 1000000000).toStringAsFixed(1)}B';
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }
}