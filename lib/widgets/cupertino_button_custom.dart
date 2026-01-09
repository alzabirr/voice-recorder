import 'package:flutter/cupertino.dart';

class CupertinoButtonCustom extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const CupertinoButtonCustom({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      color: color,
      padding: padding ?? const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(50),
      onPressed: onPressed,
      child: child,
    );
  }
}
