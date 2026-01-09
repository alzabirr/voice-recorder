import 'package:intl/intl.dart';

class FormatUtils {
  static String formatDuration(Duration duration, {bool showMilliseconds = false}) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (showMilliseconds) {
      // Convert milliseconds to centiseconds (hundredths of a second)
      String centi = twoDigits((duration.inMilliseconds.remainder(1000) / 10).floor());
      return "$twoDigitMinutes:$twoDigitSeconds.$centi";
    }
    
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy  h:mm a').format(date);
  }
}
