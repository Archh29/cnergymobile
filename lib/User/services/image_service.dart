class ImageService {
  static const String baseUrl = 'http://localhost/cynergy';
  
  static String getImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';
    
    // If it's already a full URL, return as is
    if (imagePath.startsWith('http')) {
      // Use proxy for CORS
      final fileName = imagePath.split('/').last;
      return '$baseUrl/image_proxy.php?path=$fileName';
    }
    
    // If it's just a filename, use proxy
    return '$baseUrl/image_proxy.php?path=$imagePath';
  }
}
