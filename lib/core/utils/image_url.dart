/// Cloudinary URL transform helpers.
///
/// Mặc định product image lưu URL gốc kiểu:
/// https://res.cloudinary.com/dxgy8ilqu/image/upload/e_background_removal/f_png/xxx
///
/// Inject thêm `f_auto,q_auto,w_<size>` để Cloudinary serve thumbnail
/// WebP/AVIF nhỏ hơn 5-10x cho list view → ảnh load nhanh hơn.
class ImageUrl {
  /// Thumbnail width (px). 400 đủ cho card list trên mobile retina.
  static String thumbnail(String url, {int width = 400}) {
    if (url.isEmpty) return url;
    if (!url.contains('res.cloudinary.com')) return url;
    // Insert transform sau '/upload/'
    const marker = '/upload/';
    final idx = url.indexOf(marker);
    if (idx < 0) return url;
    final head = url.substring(0, idx + marker.length);
    final tail = url.substring(idx + marker.length);
    return '${head}f_auto,q_auto,w_$width/$tail';
  }

  /// Full size cho product detail page (giữ kích thước to hơn).
  static String fullsize(String url, {int width = 1000}) {
    return thumbnail(url, width: width);
  }
}
