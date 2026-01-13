import 'package:flutter/material.dart';
import 'package:flutter_document_viewer/flutter_document_viewer.dart';

import '../helper/download_file/download_file.dart';
import '../models/download_file_type/download_file_type.dart';
import '../utils/app_colors.dart';
import '../utils/app_functions/app_functions.dart';


class DocumentViewerScreen extends StatefulWidget {
  final String doc;

  const DocumentViewerScreen({super.key, required this.doc});

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  late final FlutterDocumentViewerController _controller;

  bool _isDownloading = false;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = FlutterDocumentViewerController(
      onReady: () {},
      onPageChanged: (currentPage, totalPages) {
        debugPrint('Page changed to $currentPage of $totalPages');
      },
    );
  }

  Future<void> _downloadFile() async {
    setState(() {
      _isDownloading = true;
      _progress = 0;
    });

    await DownloadFileHelper().startDownloading(
      context: context,
      okCallback: (received, total) {
        if (total != -1) {
          setState(() {
            _progress = received / total;
          });
        }
      },
      fileUrl: widget.doc,
      type: DownloadFileType.file,
      fileName: AppFunctions.getFileNameFromUrl(widget.doc),
    );

    setState(() {
      _isDownloading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: _downloadFile,
            icon: Icon(Icons.download,
            color: AppColors.mainColor,),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Document viewer
          FlutterDocumentViewer(
            url: widget.doc,
            controller: _controller,
            showControls: false,
            onPageChanged: (currentPage, totalPages) {
              debugPrint('Page changed callback: $currentPage of $totalPages');
            },
          ),

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
    );
  }
}
