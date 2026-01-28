import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/family_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/toast_utils.dart';

/// Shows the family info bottom sheet with loading state
void showFamilyInfoSheet({
  required BuildContext context,
  required FirestoreService firestoreService,
  required String userId,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final primaryColor = Theme.of(context).colorScheme.primary;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => FamilyInfoSheetContent(
      firestoreService: firestoreService,
      userId: userId,
      isDark: isDark,
      primaryColor: primaryColor,
      parentContext: context,
    ),
  );
}

/// Stateful widget for family info to load data efficiently
class FamilyInfoSheetContent extends StatefulWidget {
  final FirestoreService firestoreService;
  final String userId;
  final bool isDark;
  final Color primaryColor;
  final BuildContext parentContext;

  const FamilyInfoSheetContent({
    super.key,
    required this.firestoreService,
    required this.userId,
    required this.isDark,
    required this.primaryColor,
    required this.parentContext,
  });

  @override
  State<FamilyInfoSheetContent> createState() => _FamilyInfoSheetContentState();
}

class _FamilyInfoSheetContentState extends State<FamilyInfoSheetContent> {
  bool _isLoading = true;
  FamilyModel? _family;
  List<UserModel> _members = [];
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userProfile = await widget.firestoreService.getUserProfile(widget.userId);
      if (userProfile?.familyId == null) {
        if (mounted) Navigator.pop(context);
        return;
      }
      
      final family = await widget.firestoreService.getFamily(userProfile!.familyId!);
      if (family == null) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final members = await widget.firestoreService.getFamilyMembers(userProfile.familyId!);
      
      if (mounted) {
        setState(() {
          _family = family;
          _members = members;
          _isOwner = widget.userId == family.ownerId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.family_restroom, size: 40, color: widget.primaryColor),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: widget.primaryColor),
                  ),
                  const SizedBox(height: 12),
                  Text('Loading...', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            )
          else
            _buildContent(),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_family == null) return const SizedBox();
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Family Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.family_restroom, size: 40, color: widget.primaryColor),
          ),
          const SizedBox(height: 16),
          
          // Family Name
          Text(
            _family!.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          // Family Code Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.primaryColor.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  'FAMILY CODE',
                  style: TextStyle(
                    color: widget.primaryColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _family!.code,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                        color: widget.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _family!.code));
                        ToastUtils.showSuccess(widget.parentContext, 'Code copied!');
                      },
                      icon: Icon(Icons.copy, color: widget.primaryColor),
                      tooltip: 'Copy Code',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Share this code with family members',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Members Section
          Row(
            children: [
              Text(
                'Members (${_members.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              if (_isOwner)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Admin Mode', style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          ..._members.map((member) => _buildMemberTile(member)),
        ],
      ),
    );
  }

  Widget _buildMemberTile(UserModel member) {
    final isMemberOwner = member.id == _family!.ownerId;
    final isCurrentUser = member.id == widget.userId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.primaryColor.withOpacity(0.15),
            ),
            clipBehavior: Clip.antiAlias,
            child: member.photoUrl != null && member.photoUrl!.isNotEmpty
                ? Image.network(
                    member.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                          style: TextStyle(color: widget.primaryColor, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                      style: TextStyle(color: widget.primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('You', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                Text(
                  member.email,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (isMemberOwner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Owner',
                style: TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold),
              ),
            )
          else if (_isOwner) ...[
            _buildOwnerActions(member),
          ],
        ],
      ),
    );
  }

  Widget _buildOwnerActions(UserModel member) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.grey.shade600, size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) async {
        Navigator.pop(context);
        
        if (value == 'transfer') {
          final confirm = await showDialog<bool>(
            context: widget.parentContext,
            builder: (ctx) => AlertDialog(
              title: const Text('Transfer Ownership'),
              content: Text('Are you sure you want to make ${member.name} the new owner?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Transfer', style: TextStyle(color: Colors.orange)),
                ),
              ],
            ),
          );
          if (confirm == true) {
            try {
              await widget.firestoreService.transferOwnership(_family!.id, member.id, widget.userId);
              ToastUtils.showSuccess(widget.parentContext, 'Ownership transferred!');
            } catch (e) {
              ToastUtils.showError(widget.parentContext, 'Error: $e');
            }
          }
        } else if (value == 'remove') {
          final confirm = await showDialog<bool>(
            context: widget.parentContext,
            builder: (ctx) => AlertDialog(
              title: const Text('Remove Member'),
              content: Text('Are you sure you want to remove ${member.name}?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Remove', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          if (confirm == true) {
            try {
              await widget.firestoreService.removeFamilyMember(_family!.id, member.id, widget.userId);
              ToastUtils.showWarning(widget.parentContext, '${member.name} removed');
            } catch (e) {
              ToastUtils.showError(widget.parentContext, 'Error: $e');
            }
          }
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'transfer',
          child: Row(
            children: [
              Icon(Icons.swap_horiz, color: Colors.orange, size: 20),
              SizedBox(width: 10),
              Text('Transfer Ownership'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'remove',
          child: Row(
            children: [
              Icon(Icons.person_remove, color: Colors.red, size: 20),
              SizedBox(width: 10),
              Text('Remove Member', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}
