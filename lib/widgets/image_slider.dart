import 'package:flutter/material.dart';

class ImageSlider extends StatefulWidget {
  final List<String> images;
  const ImageSlider({super.key, required this.images});

  @override
  State<ImageSlider> createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  int _index = 0;
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) => Image.network(
            widget.images[i],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.black12),
          ),
        ),

        // üst gradient: text/ikon okunur
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [
                  Colors.black.withOpacity(0.55),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // dot indicator
        Positioned(
          left: 0,
          right: 0,
          bottom: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.images.length, (i) {
              final active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 7,
                width: active ? 18 : 7,
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.white70,
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
