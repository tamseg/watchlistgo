import 'package:flutter/material.dart';
import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';

class ActionMenu extends StatefulWidget {
  final VoidCallback onRemove;

  const ActionMenu({super.key, required this.onRemove});

  @override
  State<ActionMenu> createState() => _ActionMenuState();
}

class _ActionMenuState extends State<ActionMenu> {
  final CustomPopupMenuController _controller = CustomPopupMenuController();

  Widget _buildMenu() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: () {
            _controller.hideMenu();
            widget.onRemove();
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.red, size: 20),
                SizedBox(width: 12),
                Text(
                  'Remove',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomPopupMenu(
      controller: _controller,
      menuBuilder: _buildMenu,
      pressType: PressType.singleClick,
      barrierColor: Colors.transparent,
      position: PreferredPosition.bottom,
      horizontalMargin: 84.0,
      verticalMargin: -34.0,
      showArrow: false,
      child: AbsorbPointer(
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(Icons.more_vert, color: Colors.grey[600]),
          onPressed: () {},
        ),
      ),
    );
  }
}
