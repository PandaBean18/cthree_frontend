import 'package:flutter/material.dart';
import 'package:cthree/core/api/deliverable_repository.dart';
import 'package:cthree/core/models/deliverable_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cthree/core/api/deliverable_provider.dart';
import 'package:provider/provider.dart';
import 'package:cthree/features/creator_flow/screens/individual_deliverable_screen.dart';


class DeliverablesScreen extends StatefulWidget {
  const DeliverablesScreen({super.key});

  @override  
  State<DeliverablesScreen> createState() => _DeliverableScreenState();
}

class _DeliverableScreenState extends State<DeliverablesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliverableProvider>().fetchAll();
    });
  }

  Future<void> _handleRefresh() async {
    await context.read<DeliverableProvider>().fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliverableProvider>();
    final _deliverables = provider.allDeliverables;
    final _isLoading = provider.isLoading;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Your Deliverables',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        )
      ),
      body: _isLoading
      ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary,),)
      : RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _deliverables == null || _deliverables!.isEmpty
        ? _buildEmptyState()
        : ListView.builder(
          padding: EdgeInsets.all(20),
          itemCount: _deliverables!.length,
          itemBuilder: (context, index) => _buildDeliverableCard(_deliverables[index]!),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text("No active deliverables found.", 
        style: TextStyle(color: Color(0xFF6F7685))),
    );
  }

  String _getDueTimerString(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final difference = dateOnly.difference(today).inDays;

    if (difference == 0) return "Due Today";
    if (difference == 1) return "Due Tomorrow";
    if (difference == -1) return "Overdue";

    final months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
    return "Due ${dueDate.day} ${months[dueDate.month - 1]}";
  }

  Widget _buildDeliverableCard(DeliverableModel deliverable) {
    final statusColor = _getStatusColor(deliverable.status);
    final dueString = _getDueTimerString(deliverable.dueDate);
    final isUrgent = dueString == "Due Today" || dueString == "Overdue";

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => IndividualDeliverableScreen(deliverableId: deliverable.id)));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUrgent ? Colors.redAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
            width: 1
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: '${deliverable.deliverableType[0].toUpperCase() + deliverable.deliverableType.substring(1)} for ',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: GoogleFonts.robotoMono().fontFamily
                          )
                        ),
                        TextSpan(
                          text: deliverable.campaignParticipant.campaign.title,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontFamily: GoogleFonts.robotoMono().fontFamily,
                            fontStyle: FontStyle.italic
                          )
                        )
                      ]
                    ),
                  )
                ),
                const SizedBox(width: 8),

                Text(
                  dueString,
                  style: TextStyle(
                    color: isUrgent ? Colors.redAccent : const Color(0xFF6F7685),
                    fontSize: 12,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ]
            ),
            SizedBox(height: 16,),

            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8,),
                Text(
                  deliverable.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor, 
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.greenAccent;
      case 'rejected': return Colors.redAccent;
      case 'submitted': return Theme.of(context).colorScheme.secondary; 
      default: return const Color(0xFF6F7685);

    }
  }
}