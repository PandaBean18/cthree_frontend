import 'package:flutter/material.dart';
import 'package:cthree/core/api/deliverable_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:cthree/core/app_video_player.dart';

class IndividualDeliverableScreen extends StatefulWidget {
  final String deliverableId;


  const IndividualDeliverableScreen({super.key, required this.deliverableId});

  @override  
  State<IndividualDeliverableScreen> createState() => _IndividualDeliverableScreenState();
}

class _IndividualDeliverableScreenState extends State<IndividualDeliverableScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliverableProvider>().fetchOne(widget.deliverableId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final _deliverable = context.watch<DeliverableProvider>().deliverables[widget.deliverableId];

    if (_deliverable == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary,),),
      );
    }

    bool isApproved = _deliverable.status == 'approved';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ACTIVE DEAL', style: TextStyle(color: Theme.of(context).primaryColor),),
            const SizedBox(height: 8,),
            _buildSplitTitle(_deliverable.campaignParticipant.campaign.title),
            const SizedBox(height: 12,),

            if (_deliverable.brief != null) 
              Text(_deliverable.brief!, style: TextStyle(color: Color(0xFF6F7685), fontSize: 14),),
            if (_deliverable.brief != null)
              const SizedBox(height: 24,),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.surface),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_deliverable.deliverableType.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              )
            ),

            const SizedBox(height: 40,),
            const Text("Timeline", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),),
            const SizedBox(height: 24,),

            _buildTimelineStep(title: "Deliverable Accepted", subtitle: "Initial contract confirmed", isCompleted: true),
            _buildTimelineStep(
              title: "Content Draft",
              subtitle: _deliverable.status.toUpperCase(),
              isCurrent: !isApproved,
              isCompleted: isApproved,
              feedback: _deliverable.feedback
            ),
            _buildTimelineStep(title: 'Final Post', subtitle: 'Post on social(s)', isCurrent: isApproved, isCompleted: false, isLast: true),
            const SizedBox(height: 32),

            if (!isApproved)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => {print('submit proof')} , 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Submit Draft', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
                ),
              ),

            if (isApproved)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => {print('Final submission')} , 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Request Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
                ),
              ),

            const SizedBox(height: 40,),
            if (_deliverable.submissionProofId != null) ...[
              const Text('Last Submission', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
              const SizedBox(height: 16,),
              _buildMediaThumbnail(
                url: _deliverable.submissionProof!.url, 
                thumbnailUrl: _deliverable.submissionProof!.thumbnailUrl, 
                mediaType: _deliverable.submissionProof!.mediaType)
            ],
            const SizedBox(height: 100,)
          ],
        ),
      ),
    );
  }

  Widget _buildMediaThumbnail({required String url, required String thumbnailUrl, required String mediaType}) {
    return GestureDetector(
      onTap: () => _showExpandedMedia(url, mediaType),
      child: Container(
        width: 200,
        height: 400,
        margin: const EdgeInsets.only(left: 16, bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: NetworkImage(thumbnailUrl),
            fit: BoxFit.cover
          ),
        ),
        child: Stack(
          children: [
            if (mediaType == 'video')
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

  Widget _buildTimelineStep({required String title, required String subtitle,  bool isCompleted = false, bool isCurrent = false, bool isLast = false, String? feedback}) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              if (isCompleted)
                Icon(Icons.check_circle, color: Theme.of(context).primaryColor, size: 24,)
              else if (isCurrent)
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Theme.of(context).colorScheme.secondary, width: 2)),
                  child: Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary, shape: BoxShape.circle),),),
                )
              else 
                Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2)),),
              if (!isLast) Expanded(child: Container(width: 2, color: Theme.of(context).colorScheme.surface,),),
            ],
          ),
          const SizedBox(width: 16,),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: isCurrent || isCompleted ? Colors.white : const Color(0xFF6F7685), fontWeight: FontWeight.bold),),
                Text(subtitle, style: const TextStyle(color: Color(0xFF6F7685), fontSize: 12),),
                if (feedback != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(feedback, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
                const SizedBox(height: 24),
              ],
            )
          ),
        ],
      ),
    );
  }

  Widget _buildSplitTitle(String title) {
    List<String> words = title.split(' ');

    if (words.length <= 1) {
      return Text(title, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),);
    }

    int middle = (words.length / 2).ceil();
    String firstHalf = words.sublist(0, middle).join(' ');
    String seconfHalf = words.sublist(middle).join(' ');

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
        children: [
          TextSpan(text: "$firstHalf ", style: const TextStyle(color: Colors.white)),
          TextSpan(text: seconfHalf, style: TextStyle(color: Theme.of(context).primaryColor, fontStyle: FontStyle.italic))
        ]
      )
    );

  }
}