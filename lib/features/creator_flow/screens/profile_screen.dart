import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:chart_sparkline/chart_sparkline.dart';
import 'package:cthree/core/models/profile_model.dart';
import 'package:cthree/core/api/profile_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cthree/features/creator_flow/progress_arc_painter.dart';
import 'package:cthree/core/app_video_player.dart';

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

  Future<void> _handleSampleWorkUpload() async {
    final XFile? media = await _sampleWorkPicker.pickMedia(
      imageQuality: 80,
    );

    if (media == null) return;

    _profileRepo.uploadSampleWork(media).listen(
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

  Widget _buildSampleWorkSection() {
    final portfolio = _profile?.portfolio ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            'SAMPLE WORK', 
            style: TextStyle(color: Color(0xFF6F7685), fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 200,
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
      onTap: _isSampleWorkUploading ? null : _handleSampleWorkUpload,
      child: Container(
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

  Widget _buildMediaThumbnail(PortfolioItem item) {
    return GestureDetector(
      onTap: () => _showExpandedMedia(item.url, item.mediaType),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(left: 16, bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: NetworkImage(item.thumbnailUrl),
            fit: BoxFit.cover
          ),
        ),
        child: Stack(
          children: [
            if (item.mediaType == 'video')
              const Center(child: Icon(Icons.play_circle_outline, color: Colors.white, size: 32)),
          ],
        ),
      ),
    );
  }

  void _showExpandedMedia(String url, String mediaType) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: mediaType == 'image' 
              ? InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              )
              : AppVideoPlayer(url: url),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
      )
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
}