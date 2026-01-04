import 'package:flutter/material.dart';

class SkeletonContainer extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const SkeletonContainer._({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.margin,
    this.padding,
  });

  factory SkeletonContainer.square({
    Key? key,
    required double size,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
  }) {
    return SkeletonContainer._(
      key: key,
      width: size,
      height: size,
      borderRadius: borderRadius,
      margin: margin,
      padding: padding,
    );
  }

  factory SkeletonContainer.circular({
    Key? key,
    required double size,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
  }) {
    return SkeletonContainer._(
      key: key,
      width: size,
      height: size,
      shape: BoxShape.circle,
      margin: margin,
      padding: padding,
    );
  }

  factory SkeletonContainer.rectangular({
    Key? key,
    double width = double.infinity,
    required double height,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
  }) {
    return SkeletonContainer._(
      key: key,
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(4),
      margin: margin,
      padding: padding,
    );
  }

  @override
  State<SkeletonContainer> createState() => _SkeletonContainerState();
}

class _SkeletonContainerState extends State<SkeletonContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            margin: widget.margin,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: widget.shape == BoxShape.circle
                  ? null
                  : (widget.borderRadius ?? BorderRadius.circular(4)),
              shape: widget.shape,
            ),
          ),
        );
      },
    );
  }
}
