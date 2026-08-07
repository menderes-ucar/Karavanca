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

  // 🌲 Akıllı Görsel Oluşturucu
  Widget _buildImage(String path) {
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.black12),
      );
    }

    return Image.network(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/camps/orman.png',
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🌲 Eğer resim listesi boşsa varsayılan resmimiz olan orman.png'yi göster
    final displayImages = widget.images.isEmpty
        ? ['assets/images/camps/orman.png']
        : widget.images;

    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: displayImages.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) => _buildImage(displayImages[i]),
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
        if (displayImages.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(displayImages.length, (i) {
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