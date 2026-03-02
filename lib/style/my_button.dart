// Copyright 2023, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';

class MyButton extends StatefulWidget {
  final Widget child;

  final VoidCallback? onPressed;

  /// Màu nền nút. Null = dùng theme.
  final Color? backgroundColor;

  /// Màu viền nút. Null = không viền.
  final Color? borderColor;

  /// Màu chữ/icon. Null = dùng theme.
  final Color? foregroundColor;

  const MyButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.borderColor,
    this.foregroundColor,
  });

  @override
  State<MyButton> createState() => _MyButtonState();
}

class _MyButtonState extends State<MyButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasCustomColors = widget.backgroundColor != null ||
        widget.borderColor != null ||
        widget.foregroundColor != null;

    final ButtonStyle? style = hasCustomColors
        ? FilledButton.styleFrom(
            backgroundColor: widget.backgroundColor ?? colorScheme.primary,
            foregroundColor: widget.foregroundColor ?? colorScheme.onPrimary,
            side: widget.borderColor != null
                ? BorderSide(color: widget.borderColor!, width: 2.5)
                : null,
          )
        : null;

    return MouseRegion(
      onEnter: (event) {
        _controller.repeat();
      },
      onExit: (event) {
        _controller.stop(canceled: false);
      },
      child: RotationTransition(
        turns: _controller.drive(const _MySineTween(0.005)),
        child: FilledButton(
          onPressed: widget.onPressed,
          style: style,
          child: widget.child,
        ),
      ),
    );
  }
}

class _MySineTween extends Animatable<double> {
  final double maxExtent;

  const _MySineTween(this.maxExtent);

  @override
  double transform(double t) {
    return sin(t * 2 * pi) * maxExtent;
  }
}
