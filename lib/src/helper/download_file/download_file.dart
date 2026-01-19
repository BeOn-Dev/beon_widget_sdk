import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/download_file_type/download_file_type.dart';
import '../../utils/app_functions/app_functions.dart';

class DownloadFileHelper {
  bool isSuccess = false;

  Future<bool> startDownloading(
      {required context,
      required final Function(int received, int total) okCallback,
      required String fileUrl,
      required String fileName,
      DownloadFileType type = DownloadFileType.file}) async {
    String path = await _getFilePath(fileName);
    AppFunctions.logPrint(message: "Download Path: $path");

    Dio dio = Dio();
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    );

    try {
      final response = await dio.download(
        fileUrl,
        path,
        onReceiveProgress: okCallback,
        options: Options(
          headers: {HttpHeaders.acceptEncodingHeader: "identity"},
        ),
      );

      isSuccess = response.statusCode == 200;
    } catch (e) {
      AppFunctions.logPrint(message: "Download error: $e");
      isSuccess = false;
    }

    if (isSuccess) {
      await _shareFile(path: path, type: type);
    }

    return isSuccess;
  }

  Future<String> _getFilePath(String filename) async {
    Directory? dir;

    try {
      // Use temp directory since we're sharing, not saving permanently
      dir = await getTemporaryDirectory();
    } catch (e) {
      AppFunctions.logPrint(message: "Error getting directory: $e");
    }

    final cleanName =
        filename.replaceAll(RegExp(r'[^\w\s.-]'), '').replaceAll(' ', '_');
    return "${dir?.path}/$cleanName";
  }

  Future<void> _shareFile({required String path, required DownloadFileType type}) async {
    String subject;
    switch (type) {
      case DownloadFileType.image:
        subject = 'Share Image';
      case DownloadFileType.video:
        subject = 'Share Video';
      case DownloadFileType.file:
        subject = 'Share File';
    }

    await SharePlus.instance.share(ShareParams(
      subject: subject,
      files: [XFile(path)],
    ));
  }
}
