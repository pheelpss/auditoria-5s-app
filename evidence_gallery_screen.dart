import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/entities/evidence.dart';

/// Read-only gallery of the photos belonging to the current audit.
class EvidenceGalleryScreen extends StatefulWidget {
  EvidenceGalleryScreen({super.key, required List<Evidence> photos, required this.initialIndex})
      : photos = List<Evidence>.unmodifiable(photos),
        assert(photos.length > 0),
        assert(initialIndex >= 0 && initialIndex < photos.length);

  final List<Evidence> photos;
  final int initialIndex;

  @override
  State<EvidenceGalleryScreen> createState() => _EvidenceGalleryScreenState();
}

class _EvidenceGalleryScreenState extends State<EvidenceGalleryScreen> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  void _move(int step) {
    final target = _index + step;
    if (target < 0 || target >= widget.photos.length) return;
    _controller.animateToPage(target,
        duration: const Duration(milliseconds: 240), curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030711),
      appBar: AppBar(
        backgroundColor: const Color(0xFF030711),
        foregroundColor: Colors.white,
        leading: IconButton(
          key: const Key('gallery-close'),
                    tooltip: 'Fechar fotos',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Fotos da auditoria'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                key: const Key('evidence-gallery-pages'),
                controller: _controller,
                itemCount: widget.photos.length,
                onPageChanged: (index) => setState(() => _index = index),
                itemBuilder: (context, index) {
                  final photo = widget.photos[index];
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.file(
                      File(photo.filePath),
                      fit: BoxFit.contain,
                      // Bound decoding memory while retaining detail on phones.
                      cacheWidth: 2048,
                      semanticLabel: 'Foto ${index + 1} de ${widget.photos.length}',
                      errorBuilder: (_, __, ___) => const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
                            SizedBox(height: 12),
                            Text('Não foi possível abrir esta foto.',
                                style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(widget.photos[_index].fileName,
                  maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    key: const Key('gallery-previous'),
                    tooltip: 'Foto anterior',
                    iconSize: 32,
                    color: Colors.white,
                    disabledColor: Colors.white24,
                    onPressed: _index > 0 ? () => _move(-1) : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Semantics(
                    liveRegion: true,
                    child: Text('${_index + 1} / ${widget.photos.length}',
                        key: const Key('evidence-gallery-counter'),
                        style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                  IconButton(
                    key: const Key('gallery-next'),
                    tooltip: 'Próxima foto',
                    iconSize: 32,
                    color: Colors.white,
                    disabledColor: Colors.white24,
                    onPressed: _index < widget.photos.length - 1 ? () => _move(1) : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
