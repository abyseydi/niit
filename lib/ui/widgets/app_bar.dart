import 'package:flutter/material.dart';
import 'package:niit/utils/colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(1);

  @override
  Widget build(BuildContext context) {
    return AppBar(backgroundColor: AppColors.k_primary);
  }
}
