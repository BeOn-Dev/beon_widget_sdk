import 'dart:io';

import 'package:flutter/material.dart';

import '../helper/download_file/download_file.dart';
import '../models/download_file_type/download_file_type.dart';
import '../utils/app_colors.dart';
import '../utils/app_functions/app_functions.dart';
import 'components/cached_network_image_widget/cached_network_image_widget.dart';

class ImageFullScreen extends StatefulWidget {
  final String image;

  const ImageFullScreen({super.key, required this.image});

  @override
  State<ImageFullScreen> createState() => _ImageFullScreenState();
}

class _ImageFullScreenState extends State<ImageFullScreen>
    with SingleTickerProviderStateMixin {
  double _progress = 0; // نسبة التحميل
  bool _isDownloading = false;

  double _offsetY = 0; // موضع السحب

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _animation = Tween<double>(begin: 0, end: 0).animate(_controller)
      ..addListener(() {
        setState(() {
          _offsetY = _animation.value;
        });
      });
  }

  void _animateBack() {
    _animation = Tween<double>(begin: _offsetY, end: 0).animate(_controller);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () async {
              // Check if widget is still mounted before starting
              if (!mounted) return;

              setState(() {
                _isDownloading = true;
                _progress = 0;
              });

              await DownloadFileHelper().startDownloading(
                context: context,
                okCallback: (received, total) {
                  // Check if widget is still mounted before updating progress
                  if (total != -1 && mounted) {
                    setState(() {
                      _progress = received / total;
                    });
                  }
                },
                fileUrl: widget.image,
                type: DownloadFileType.image,
                fileName: "BeOn.${AppFunctions.getFileExtension(widget.image)}",
              );

              // Check if widget is still mounted before final setState
              if (mounted) {
                setState(() {
                  _isDownloading = false;
                });
              }
            },
            icon: Icon(Icons.download,
              color: AppColors.mainColor,),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (mounted) {
            setState(() {
              _offsetY += details.delta.dy;
            });
          }
        },
        onVerticalDragEnd: (details) {
          if (_offsetY > 260) {
            AppFunctions.popNavigate(context: context);
          } else {
            _animateBack();
          }
        },
        child: Stack(
          children: [
            Transform.translate(
              offset: Offset(0, _offsetY),
              child: widget.image.contains("http")
                  ? CachedNetworkImageWidget(
                      image: widget.image,
                    )
                  : Image.file(File(widget.image)),
            ),

            // ⬇ Progress Indicator فوق الصورة
            if (_isDownloading)
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _progress,
                        color: AppColors.mainColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "${(_progress * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
