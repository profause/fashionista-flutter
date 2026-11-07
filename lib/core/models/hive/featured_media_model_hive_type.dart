class FeaturedMediaModelHiveType {
  static const int url = 0;
  static const int type = 1;
  static const int aspectRatio = 2;
  static const int thumbnailUrl = 3;
  static const int uid = 4;

  // Video-only fields; absent on image media.
  static const int duration = 5;
  static const int width = 6;
  static const int height = 7;
  static const int hasAudio = 8;
  static const int format = 9;
  static const int fileSize = 10;
}
