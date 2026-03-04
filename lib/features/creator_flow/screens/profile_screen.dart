import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:chart_sparkline/chart_sparkline.dart';
import 'package:cthree/core/models/profile_model.dart';
import 'package:cthree/core/api/profile_repository.dart';

class CreatorProfileScreen extends StatefulWidget {
  const CreatorProfileScreen({super.key});

  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  final ProfileRepository _profileRepo = ProfileRepository();
  ProfileModel? _profile;
  bool _isLoading = true;

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
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? url) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundImage: url != null ? NetworkImage(url) : null,
          child: url == null ? Icon(Icons.person, size: 80, color: Color(0xFF4A2B29)) : null,
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
          child: const Icon(Icons.check, color: Colors.white, size: 16),

        )
      ],
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