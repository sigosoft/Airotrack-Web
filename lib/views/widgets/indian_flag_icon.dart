import 'package:flutter/material.dart';

/// Clean vector Indian Flag Icon Widget
class IndianFlagIcon extends StatelessWidget {
  final double width;
  final double height;

  const IndianFlagIcon({
    super.key,
    this.width = 24,
    this.height = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2.5),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Saffron band
          Expanded(
            child: Container(color: const Color(0xFFFF9933)),
          ),
          // White band with Ashoka Chakra dot
          Expanded(
            child: Container(
              color: Colors.white,
              child: Center(
                child: Container(
                  width: height * 0.22,
                  height: height * 0.22,
                  decoration: const BoxDecoration(
                    color: Color(0xFF000080),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          // India Green band
          Expanded(
            child: Container(color: const Color(0xFF138808)),
          ),
        ],
      ),
    );
  }
}
