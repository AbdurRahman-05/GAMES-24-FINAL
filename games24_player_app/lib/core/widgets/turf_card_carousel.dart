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
        final raw = p.trim();
        if (raw.isEmpty || raw == 'null') continue;
        if (raw.contains('picsum.photos') || raw.contains('unsplash.com')) continue;
        final resolved = ApiConfig.resolveUrl(raw);
        if (resolved.isNotEmpty && !list.contains(resolved)) {
          list.add(resolved);
        }
      }
    }
    if (list.isEmpty && widget.fallbackImageUrl != null && widget.fallbackImageUrl!.trim().isNotEmpty) {
      final raw = widget.fallbackImageUrl!.trim();
      if (raw != 'null' && !raw.contains('picsum.photos') && !raw.contains('unsplash.com')) {
        final resolved = ApiConfig.resolveUrl(raw);
        if (resolved.isNotEmpty && !list.contains(resolved)) {
          list.add(resolved);
        }
      }
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
            // PageView for swipeable carousel OR branded placeholder
            GestureDetector(
              onTap: widget.onTap,
              child: images.isNotEmpty
                  ? (hasMultiple
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
                      : _buildImageItem(images.first))
                  : _buildPlaceholder(),
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

  Widget _buildPlaceholder() {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF141414), Color(0xFF1E1E1E), Color(0xFF0F0F0F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0.22,
            child: Image.asset(
              'assets/images/wm_full.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: widget.height,
              errorBuilder: (_, _, _) => const SizedBox(),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD4FF00).withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.stadium_rounded,
                  size: 30,
                  color: Color(0xFFD4FF00),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'GAMEZ24 VENUE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Delight',
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Verified Sports Arena',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageItem(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: widget.height,
      errorBuilder: (_, _, _) => _buildPlaceholder(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: const Color(0xFF141414),
          alignment: Alignment.center,
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: const Color(0xFFD4FF00),
            ),
          ),
        );
      },
    );
  }
}

