import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ImageService {
  // Konfigurasi Cloudinary
  static const String cloudName = 'dsqajzles';
  static const String apiKey = 'ZetJD-Nn-AlncQy7DcbifeeTszw';
  static const String apiSecret = 'ZetJD-Nn-AlncQy7DcbifeeTszw';
  static const String uploadPreset = 'kenongotask_img';

  // Upload gambar ke Cloudinary
  static Future<String?> uploadImage(File imageFile) async {
    try {
      // Siapkan request ke Cloudinary
      var uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );
      var request = http.MultipartRequest("POST", uri);

      // Tambahkan file dan parameter yang diperlukan
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
      request.fields['upload_preset'] = uploadPreset;
      request.fields['api_key'] = apiKey;
      request.fields['api_secret'] = apiSecret;
      request.fields['timestamp'] =
          DateTime.now().millisecondsSinceEpoch.toString();

      // Kirim request
      var response = await request.send();

      // Proses response
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);

      // Cek status response
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(responseString);
        final imageUrl = jsonResponse['secure_url'];
        return imageUrl;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
