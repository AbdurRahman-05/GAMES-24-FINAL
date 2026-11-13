import 'package:flutter/material.dart';
import '../../api_config.dart';

class TurfCardCarousel extends StatefulWidget {
  final List<String>? photoUrls;
  final String? fallbackImageUrl;
  final double height;
  final BorderRadius borderRadius;
  final Widget? topTrailing;
  final Widget? topLeading;
  final Widget? bottomLeading;
  final Widget? bottomTrailing;
  final VoidCallback? onTap;

  const TurfCardCarousel({
    super.key,
    this.photoUrls,
    this.fallbackImageUrl,
    this.height = 180,
    this.borderRadius = const BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
    ),
    this.topTrailing,
    this.topLeading,
    this.bottomLeading,
    this.bottomTrailing,
    this.onTap,
  });

  @override
  State<TurfCardCarousel> createState() => _TurfCardCarouselState();
}

class _TurfCardCarouselState extends State<TurfCardCarousel> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _sanitizedImages {
    final list = <String>[];
    if (widget.photoUrls != null && widget.photoUrls!.isNotEmpty) {
      for (final p in widget.photoUrls!) {
        final resolved = ApiConfig.resolveUrl(p);
        if (resolved.isNotEmpty && !list.contains(resolved)) {
          list.add(resolved);
        }
      }
    }
    if (list.isEmpty && widget.fallbackImageUrl != null && widget.fallbackImageUrl!.isNotEmpty) {
      final resolved = ApiConfig.resolveUrl(widget.fallbackImageUrl);
      if (resolved.isNotEmpty) {
        list.add(resolved);
      }
    }
    if (list.isEmpty) {
      list.add('https://picsum.photos/seed/turf1/800/400');
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final images = _sanitizedImages;
    final hasMultiple = images.length > 1;

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // PageView for swipeable carousel
            GestureDetector(
              onTap: widget.onTap,
              child: hasMultiple
                  ? PageView.builder(
                      controller: _pageController,
                      itemCount: images.length,
                      onPageChanged: (idx) {
                        setState(() => _currentIndex = idx);
                      },
                      itemBuilder: (context, index) {
                        return _buildImageItem(images[index]);
                      },
                    )
                  : _buildImageItem(images.first),
            ),

            // Subtle gradient overlay for readability of badges and dots
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.35),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Top Leading (Offer / Badge)
            if (widget.topLeading != null)
              Positioned(
                top: 12,
                left: 12,
                child: widget.topLeading!,
              ),

            // Top Trailing (Rating / Reviews)
            if (widget.topTrailing != null)
              Positioned(
                top: 12,
                right: 12,
                child: widget.topTrailing!,
              ),

            // Bottom Leading (Sports / Availability)
            if (widget.bottomLeading != null)
              Positioned(
                bottom: 12,
                left: 12,
                child: widget.bottomLeading!,
              ),

            // Bottom Trailing
            if (widget.bottomTrailing != null)
              Positioned(
                bottom: 12,
                right: 12,
                child: widget.bottomTrailing!,
              ),

            // Carousel Indicators (Dots + Count pill)
            if (hasMultiple) ...[
              // Photo Count Pill (e.g. 1/4)
              Positioned(
                top: widget.topLeading != null ? 44 : 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library_outlined, size: 11, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '${_currentIndex + 1}/${images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Dot Indicators at Bottom Center
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(images.length, (idx) {
                    final isSelected = idx == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      height: 4.5,
                      width: isSelected ? 16 : 4.5,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: widget.height,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFF3F4F6),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer_rounded, size: 36, color: Colors.grey.shade400),
            const SizedBox(height: 4),
            Text(
              'Turf Photo',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: const Color(0xFFE5E7EB),
          alignment: Alignment.center,
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              color: const Color(0xFF154D36),
            ),
          ),
        );
      },
    );
  }
}

