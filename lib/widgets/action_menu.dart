import 'package:material_ui/material_ui.dart';

class ActionMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const ActionMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  const ActionMenuItem.remove(VoidCallback onTap)
    : this(
        icon: Icons.delete_outline,
        label: 'Remove',
        onTap: onTap,
        destructive: true,
      );
}

class ActionMenu extends StatefulWidget {
  final List<ActionMenuItem> items;

  const ActionMenu({super.key, required this.items});

  @override
  State<ActionMenu> createState() => _ActionMenuState();
}

class _ActionMenuState extends State<ActionMenu>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_isOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
    setState(() => _isOpen = true);
  }

  Future<void> _closeMenu() async {
    await _animationController.reverse();
    _removeOverlay();
    if (mounted) setState(() => _isOpen = false);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeMenu,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            width: 200,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.centerLeft,
              followerAnchor: Alignment.centerRight,
              offset: const Offset(4, 14),
              child: ScaleTransition(
                scale: _expandAnimation,
                alignment: Alignment.topRight,
                child: FadeTransition(
                  opacity: _expandAnimation,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final item in widget.items) _buildItem(item),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(ActionMenuItem item) {
    final color = item.destructive ? Colors.red : Colors.grey[850];
    return InkWell(
      onTap: () => _closeMenu().then((_) => item.onTap()),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Icon(item.icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.more_vert,
          color: _isOpen ? Colors.black : Colors.grey[600],
        ),
        onPressed: _toggleMenu,
      ),
    );
  }
}
