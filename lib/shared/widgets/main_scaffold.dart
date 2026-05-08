import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// Tracks navigation history for back button behavior
final _navHistoryProvider = StateNotifierProvider<_NavHistoryNotifier, List<String>>((ref) {
  return _NavHistoryNotifier();
});

class _NavHistoryNotifier extends StateNotifier<List<String>> {
  _NavHistoryNotifier() : super(['/dashboard']);

  void push(String route) {
    if (state.isNotEmpty && state.last == route) return;
    state = [...state.where((r) => r != route), route];
  }

  String? pop() {
    if (state.length <= 1) return null;
    final newState = [...state];
    newState.removeLast();
    state = newState;
    return newState.last;
  }
}

class MainScaffold extends ConsumerWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserRoleProvider);
    final items = _getNavItems(role);
    final routes = _getRoutes(role);

    final currentPath = GoRouterState.of(context).uri.path;
    int currentIndex = 0;
    for (int i = 0; i < routes.length; i++) {
      if (currentPath == routes[i]) {
        currentIndex = i;
        break;
      }
    }

    // Track navigation history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (routes.contains(currentPath)) {
        ref.read(_navHistoryProvider.notifier).push(currentPath);
      }
    });

    final isOnHome = currentPath == '/dashboard';
    final historyNotifier = ref.read(_navHistoryProvider.notifier);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // If on home → always show exit dialog
        if (isOnHome) {
          final shouldPop = await showDialog<bool>(
            context: context,
            barrierColor: Colors.black54,
            builder: (_) => const _ExitDialog(),
          );
          if (shouldPop == true) SystemNavigator.pop();
          return;
        }

        // Not on home → go back through history
        final prev = historyNotifier.pop();
        if (prev != null) {
          context.go(prev);
        } else {
          context.go('/dashboard');
        }
      },
      child: _SwipeableScaffold(
        currentIndex: currentIndex,
        routes: routes,
        items: items,
        currentPath: currentPath,
        child: child,
      ),
    );
  }

  List<BottomNavigationBarItem> _getNavItems(UserRole? role) {
    switch (role) {
      case UserRole.murid:
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today_rounded), label: 'Jadwal'),
          BottomNavigationBarItem(icon: Icon(Icons.local_library_outlined), activeIcon: Icon(Icons.local_library_rounded), label: 'Perpustakaan'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outlined), activeIcon: Icon(Icons.person_rounded), label: 'Profil'),
        ];
      case UserRole.guru:
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outlined), activeIcon: Icon(Icons.people_rounded), label: 'Siswa'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign_outlined), activeIcon: Icon(Icons.campaign_rounded), label: 'Pengumuman'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outlined), activeIcon: Icon(Icons.person_rounded), label: 'Profil'),
        ];
      case UserRole.orangtua:
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.child_care_outlined), activeIcon: Icon(Icons.child_care_rounded), label: 'Anak Saya'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign_outlined), activeIcon: Icon(Icons.campaign_rounded), label: 'Pengumuman'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outlined), activeIcon: Icon(Icons.person_rounded), label: 'Profil'),
        ];
      default:
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outlined), activeIcon: Icon(Icons.person_rounded), label: 'Profil'),
        ];
    }
  }

  List<String> _getRoutes(UserRole? role) {
    switch (role) {
      case UserRole.murid:
        return ['/dashboard', '/subjects', '/library', '/profile'];
      case UserRole.guru:
        return ['/dashboard', '/students', '/announcements', '/profile'];
      case UserRole.orangtua:
        return ['/dashboard', '/students', '/announcements', '/profile'];
      default:
        return ['/dashboard', '/profile'];
    }
  }
}

// ─── Swipeable body with fade-scroll ───
class _SwipeableScaffold extends StatefulWidget {
  final int currentIndex;
  final List<String> routes;
  final List<BottomNavigationBarItem> items;
  final Widget child;
  final String currentPath;

  const _SwipeableScaffold({
    required this.currentIndex,
    required this.routes,
    required this.items,
    required this.child,
    required this.currentPath,
  });

  @override
  State<_SwipeableScaffold> createState() => _SwipeableScaffoldState();
}

class _SwipeableScaffoldState extends State<_SwipeableScaffold> with SingleTickerProviderStateMixin {
  double _dragStart = 0;
  double _dragDelta = 0;
  bool _isDragging = false;

  // For slide animation on tab switch
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  int _slideDirection = 0; // -1 left, 1 right

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _slideAnim = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween<double>(begin: 1.0, end: 1.0).animate(_slideController);
  }

  @override
  void didUpdateWidget(covariant _SwipeableScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPath != widget.currentPath) {
      // Determine direction
      final oldIdx = oldWidget.currentIndex;
      final newIdx = widget.currentIndex;
      _slideDirection = newIdx > oldIdx ? 1 : -1;

      _slideAnim = Tween<Offset>(
        begin: Offset(_slideDirection * 0.15, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

      _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
      );

      _slideController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _dragStart = details.globalPosition.dx;
    _dragDelta = 0;
    _isDragging = true;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _dragDelta = details.globalPosition.dx - _dragStart;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final velocity = details.primaryVelocity ?? 0;
    final threshold = MediaQuery.of(context).size.width * 0.2;

    if (_dragDelta.abs() > threshold || velocity.abs() > 500) {
      if (_dragDelta > 0 && widget.currentIndex > 0) {
        // Swipe right → previous tab
        context.go(widget.routes[widget.currentIndex - 1]);
      } else if (_dragDelta < 0 && widget.currentIndex < widget.routes.length - 1) {
        // Swipe left → next tab
        context.go(widget.routes[widget.currentIndex + 1]);
      }
    }
    _dragDelta = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragStart: _onHorizontalDragStart,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        behavior: HitTestBehavior.translucent,
        child: ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: const [
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: const [0.0, 0.03, 0.97, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: widget.child,
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: List.generate(widget.items.length, (i) {
                  final isActive = i == widget.currentIndex;
                  final item = widget.items[i];
                  return Expanded(
                    child: _NavItem(
                      icon: item.icon as Icon,
                      activeIcon: item.activeIcon as Icon,
                      label: item.label!,
                      isActive: isActive,
                      onTap: () {
                        if (i < widget.routes.length && !isActive) {
                          context.go(widget.routes[i]);
                        }
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Exit Dialog with premium animation ───
class _ExitDialog extends StatefulWidget {
  const _ExitDialog();

  @override
  State<_ExitDialog> createState() => _ExitDialogState();
}

class _ExitDialogState extends State<_ExitDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.error.withOpacity(0.15), AppColors.error.withOpacity(0.05)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.exit_to_app_rounded, color: AppColors.error, size: 32),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text('Keluar Aplikasi?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'Apakah Anda yakin ingin\nkeluar dari aplikasi?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: AppColors.divider),
                      ),
                      child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Nav item with tap scale animation ───
class _NavItem extends StatefulWidget {
  final Icon icon;
  final Icon activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _tapController.forward(),
      onTapUp: (_) {
        _tapController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _tapController.reverse(),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnim,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isActive ? 14 : 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: widget.isActive ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: widget.isActive
                  ? [BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 2))]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: IconTheme(
                    key: ValueKey(widget.isActive),
                    data: IconThemeData(color: widget.isActive ? AppColors.primary : AppColors.textMuted, size: 22),
                    child: widget.isActive ? widget.activeIcon : widget.icon,
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  child: widget.isActive
                      ? Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
