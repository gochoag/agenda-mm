import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';

class UserFilterBar extends StatelessWidget {
  final String? title;
  final List<User> users;
  final int? currentUserId;
  final int? selectedUserId;
  final ValueChanged<int?> onSelected;
  final String allLabel;
  final String myLabel;

  const UserFilterBar({
    super.key,
    this.title,
    required this.users,
    required this.currentUserId,
    required this.selectedUserId,
    required this.onSelected,
    this.allLabel = 'Todas',
    this.myLabel = 'Mis Notas',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 20, color: AppColors.textSecondary),
          if (title != null && title!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              title!,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text(allLabel),
                    selected: selectedUserId == null,
                    onSelected: (val) {
                      if (val) onSelected(null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(myLabel),
                    selected: selectedUserId == currentUserId,
                    onSelected: (val) {
                      if (val) onSelected(currentUserId);
                    },
                  ),
                  ...users
                      .where((u) => u.id != currentUserId)
                      .map((u) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: ChoiceChip(
                              label: Text('De ${u.username}'),
                              selected: selectedUserId == u.id,
                              onSelected: (val) {
                                if (val) onSelected(u.id);
                              },
                            ),
                          )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
