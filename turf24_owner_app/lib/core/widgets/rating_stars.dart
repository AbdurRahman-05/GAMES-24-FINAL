import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color color;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16.0,
    this.color = const Color(0xFFF59E0B),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (rating >= index + 1) {
          return Icon(Icons.star_rounded, size: size, color: color);
        } else if (rating >= index + 0.5) {
          return Icon(Icons.star_half_rounded, size: size, color: color);
        } else {
          return Icon(Icons.star_outline_rounded, size: size, color: color);
        }
      }),
    );
  }
}
