import 'package:flutter/foundation.dart';
import '../../models/parsed_transaction.dart';

class PopupQueueController extends ChangeNotifier {
  final List<ParsedTransaction> _queue = [];
  ParsedTransaction? _currentPopup;
  bool _isShowing = false;
  int _bannerReviewCount = 0;

  ParsedTransaction? get currentPopup => _currentPopup;
  bool get isShowing => _isShowing;
  int get bannerReviewCount => _bannerReviewCount;
  int get queueLength => _queue.length;

  void enqueue(ParsedTransaction tx) {
    if (!_isShowing && _currentPopup == null) {
      _currentPopup = tx;
      _isShowing = true;
    } else {
      _queue.add(tx);
      _bannerReviewCount++;
    }
    notifyListeners();
  }

  void markDismissed() {
    _isShowing = false;
    _currentPopup = null;
    if (_queue.isNotEmpty) {
      _currentPopup = _queue.removeAt(0);
      if (_bannerReviewCount > 0) {
        _bannerReviewCount--;
      }
      _isShowing = true;
    }
    notifyListeners();
  }

  void clearBannerCount() {
    _bannerReviewCount = 0;
    notifyListeners();
  }
}

