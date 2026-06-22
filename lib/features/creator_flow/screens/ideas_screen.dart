import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cthree/core/models/idea_model.dart';
import 'package:cthree/core/api/idea_repository.dart';
import 'package:cthree/features/creator_flow/screens/create_idea_screen.dart';

class IdeasScreen extends StatefulWidget {
  const IdeasScreen({super.key});

  @override
  State<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends State<IdeasScreen> {
  final IdeaRepository _ideaRepo = IdeaRepository();
  List<IdeaModel> _ideas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchIdeas();
  }

  Future<void> _fetchIdeas() async {
    setState(() => _isLoading = true);
    final data = await _ideaRepo.getIdeas();

    if (mounted) {
      setState(() {
        _ideas = data ?? [];
        _isLoading = false;
      });
    }
  }

  String _extractPreviewText(Map<String, dynamic> description) {
    if (!description.containsKey('ops')) return "No description";
    
    final ops = description['ops'] as List;
    String plainText = "";
    
    for (var op in ops) {
      if (op is Map && op.containsKey('insert') && op['insert'] is String) {
        plainText += op['insert'];
      }
    }
    
    final trimmed = plainText.trim().replaceAll('\n', ' ');
    return trimmed.isEmpty ? "No description" : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Workspace',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Theme.of(context).primaryColor),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateIdeaScreen()),
              );

              if (result == true) {
                _fetchIdeas(); // Reload the list to show the new idea
              }
            },
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary))
          : _ideas.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: Theme.of(context).colorScheme.secondary,
                  onRefresh: _fetchIdeas,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _ideas.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildIdeaCard(_ideas[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E222A),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Icon(
                Icons.lightbulb_outline_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "All great masterpieces\nbegin as a single thought.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Tap the + button to open your canvas and capture your next big inspiration.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6F7685),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateIdeaScreen()),
                );

                if (result == true) {
                  _fetchIdeas(); // Reload the list to show the new idea
                }
              },
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              label: const Text(
                "New Workspace",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildIdeaCard(IdeaModel idea) {
    final previewText = _extractPreviewText(idea.description);
    final dateString = DateFormat('MMM d, yyyy').format(idea.updatedAt);

    return GestureDetector(
      onTap: () {
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E222A), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    idea.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateString,
                  style: const TextStyle(color: Color(0xFF6F7685), fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              previewText,
              style: const TextStyle(color: Color(0xFF6F7685), fontSize: 14, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (idea.inspos.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInsposRow(idea.inspos),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInsposRow(List<InspoModel> inspos) {
    final displayInspos = inspos.take(4).toList();
    final extraCount = inspos.length - displayInspos.length;

    return Row(
      children: [
        const Icon(Icons.attachment_rounded, size: 14, color: Color(0xFF6F7685)),
        const SizedBox(width: 6),
        const Text("Inspos:", style: TextStyle(color: Color(0xFF6F7685), fontSize: 12)),
        const SizedBox(width: 8),
        ...displayInspos.map((inspo) {
          return Container(
            margin: const EdgeInsets.only(right: 6),
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF1E222A),
              borderRadius: BorderRadius.circular(6),
              image: inspo.thumbnailUrl != null
                  ? DecorationImage(
                      image: NetworkImage(inspo.thumbnailUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: inspo.thumbnailUrl == null
                ? const Icon(Icons.broken_image, size: 12, color: Color(0xFF6F7685))
                : null,
          );
        }),
        if (extraCount > 0)
          Container(
            height: 24,
            width: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1E222A),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "+$extraCount",
              style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          )
      ],
    );
  }
}