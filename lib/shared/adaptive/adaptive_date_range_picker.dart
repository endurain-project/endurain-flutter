import 'package:endurain/core/utils/platform_utils.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

Future<DateTimeRange?> showAdaptiveDateRangePicker({
  required BuildContext context,
  required DateTime initialStart,
  required DateTime initialEnd,
  required DateTime firstDate,
  required DateTime lastDate,
  required String startLabel,
  required String endLabel,
  required String cancelLabel,
  required String confirmLabel,
}) async {
  if (!PlatformUtils.isApplePlatform) {
    return showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: '$startLabel - $endLabel',
      cancelText: cancelLabel,
      confirmText: confirmLabel,
    );
  }

  var start = initialStart;
  var end = initialEnd;
  return showCupertinoModalPopup<DateTimeRange>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => CupertinoActionSheet(
        title: Text('$startLabel - $endLabel'),
        message: SizedBox(
          height: 360,
          child: Column(
            children: [
              Text(startLabel),
              SizedBox(
                height: 150,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: start,
                  minimumDate: firstDate,
                  maximumDate: end,
                  onDateTimeChanged: (value) {
                    setModalState(() => start = value);
                  },
                ),
              ),
              Text(endLabel),
              SizedBox(
                height: 150,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: end,
                  minimumDate: start,
                  maximumDate: lastDate,
                  onDateTimeChanged: (value) {
                    setModalState(() => end = value);
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () =>
                Navigator.pop(context, DateTimeRange(start: start, end: end)),
            child: Text(confirmLabel),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(cancelLabel),
        ),
      ),
    ),
  );
}
