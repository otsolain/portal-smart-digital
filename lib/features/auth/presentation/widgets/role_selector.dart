import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';

class RoleSelector extends StatelessWidget {
  final UserRole selectedRole;
  final ValueChanged<UserRole> onRoleChanged;

  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children:
          UserRole.values.map((role) {
            final isSelected = role == selectedRole;
            final color = _getRoleColor(role);
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: role == UserRole.murid ? 0 : 4,
                  right: role == UserRole.guru ? 0 : 4,
                ),
                child: GestureDetector(
                  onTap: () => onRoleChanged(role),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? color : const Color(0xFFF3FAFD),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? color : const Color(0x000ffddd),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getRoleIcon(role),
                          size: 24,
                          color:
                              isSelected
                                  ? Colors.white
                                  : const Color(0xFF217093),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          role.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                isSelected
                                    ? Colors.white
                                    : const Color(0xFF217093),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.murid:
        return const Color(0xFF217093);
      case UserRole.orangtua:
        return const Color(0xFF00897B);
      case UserRole.guru:
        return const Color(0xFFE65100);
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.murid:
        return Icons.school;
      case UserRole.orangtua:
        return Icons.people;
      case UserRole.guru:
        return Icons.assignment_ind;
    }
  }
}
