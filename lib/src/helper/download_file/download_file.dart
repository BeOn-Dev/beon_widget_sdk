import 'dart:io';
import 'dart:typed_data';


import 'package:dio/dio.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/download_file_type/download_file_type.dart';
import '../../utils/app_functions/app_functions.dart';
import '../app_alert/app_alert.dart';

class DownloadFileHelper {
  bool isSuccess = false;

  Future<bool> startDownloading(
      {required context,
      required final Function(int received, int total) okCallback,
      required String fileUrl,
      required String fileName,
      DownloadFileType type = DownloadFileType.file}) async {
    // if (Platform.isAndroid) {
    //   final status = await Permission.photos.request();
    //   if (!status.isGranted) {
    //     AppAlert.error(message: "Permission denied", context: context);
    //     openAppSettings();
    //     return false;
    //   }
    // }

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
      // AppAlert.error(message: e.toString(), context: context);
      isSuccess = false;
    }

    if (isSuccess) {
      if (type != DownloadFileType.file) {
        await _saveNetworkImage(
            url: fileUrl, context: context, type: type, savePath: path);
      } else {
        if (Platform.isAndroid) {
          AppAlert.success(
            message:"File Downloaded Successfully",
            context: context,
            isTranslated: true,
          );
        } else {
          AppFunctions.logPrint(message: "Share it ");
          await _saveAndShareFile(path);
        }
        OpenFilex.open(path);
      }
    }

    return isSuccess;
  }

  Future<String> _getFilePath(String filename) async {
    Directory? dir;

    try {
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        dir = await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      AppFunctions.logPrint(message: "Error getting directory: $e");
    }

    final cleanName =
        filename.replaceAll(RegExp(r'[^\w\s.-]'), '').replaceAll(' ', '_');
    return "${dir?.path}/$cleanName";
  }

  _saveAndShareFile(String filePath) async {
    await SharePlus.instance.share(ShareParams(
      text: 'Great picture',
      files: [XFile(filePath)],
    ));
  }

  Future<void> _saveNetworkImage(
      {required String url,
      required context,
      required DownloadFileType type,
      required String savePath}) async {
    try {
      AppFunctions.logPrint(
          message:
              "Pathhhhh: ${savePath}    Typeeeee: ${type}  is Imageeeeeeee  ${type == DownloadFileType.image}");
      final response = (type == DownloadFileType.image)
          ? await Dio().get(
              url,
              options: Options(responseType: ResponseType.bytes),
            )
          : null;

      final String uniqueFileName = type == DownloadFileType.image
          ? "img_${DateTime.now().millisecondsSinceEpoch}"
          : "video_${DateTime.now().millisecondsSinceEpoch}";

      final result = await (type == DownloadFileType.image
          ? ImageGallerySaverPlus.saveImage(
              Uint8List.fromList(response?.data),
              quality: 60,
              name: uniqueFileName,
            )
          : ImageGallerySaverPlus.saveFile(
              savePath,
              name: uniqueFileName,
            ));
      AppAlert.success(
          message: "Save to gallery successfully",
          context: context,
          isTranslated: true);
      AppFunctions.logPrint(message: "Saved to Gallery: $result");
    } catch (e) {
      AppFunctions.logPrint(message: "Error saving image: $e");
    }
  }
}
