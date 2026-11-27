import 'package:endurain/features/activity/models/recording_live_activity_content.dart';
import 'package:endurain/features/activity/services/recording_live_activity_adapter.dart';

/// Records the Live Activity content it is given, and fails while [failing].
class FakeRecordingLiveActivityAdapter implements RecordingLiveActivityAdapter {
  final List<RecordingLiveActivityContent> updates = [];
  bool failing = false;

  @override
  Future<void> update(RecordingLiveActivityContent content) async {
    updates.add(content);
    if (failing) {
      throw StateError('Live Activity unavailable');
    }
  }
}
