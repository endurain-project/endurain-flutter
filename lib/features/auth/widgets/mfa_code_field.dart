import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// The kind of code that answers the MFA step.
enum MfaCodeKind {
  /// A 6-digit code from an authenticator app.
  totp(length: 6, groupSize: 3),

  /// A one-time backup code, `XXXX-XXXX` of letters and digits.
  backupCode(length: 8, groupSize: 4);

  const MfaCodeKind({required this.length, required this.groupSize});

  /// Characters the user types, without the backup code's dash.
  final int length;

  /// Characters shown together, before a gap (or a backup code's dash).
  final int groupSize;

  RegExp get _disallowed =>
      this == totp ? RegExp('[^0-9]') : RegExp('[^A-Z0-9]');

  /// [input] reduced to the characters this kind accepts, uppercased and cut
  /// to [length]. A pasted `a3k9-7bdf` becomes `A3K97BDF`.
  String normalize(String input) {
    final kept = input.toUpperCase().replaceAll(_disallowed, '');
    return kept.length > length ? kept.substring(0, length) : kept;
  }

  /// The code as the server expects it: a backup code regains its dash.
  String toSubmission(String typed) {
    final code = normalize(typed);
    if (this == backupCode && code.length == length) {
      return '${code.substring(0, groupSize)}-${code.substring(groupSize)}';
    }
    return code;
  }
}

/// A code entry shown as one box per character, for the MFA step.
///
/// A single invisible text field takes the input, so typing, deleting,
/// pasting and one-time-code autofill work as in any text field; the boxes
/// only show what it holds. [controller] holds the characters without the
/// backup code's dash; [MfaCodeKind.toSubmission] adds it back.
///
/// [onCompleted] runs once each time the last box is filled, by typing,
/// pasting or autofill, so the code can be sent without a tap.
class MfaCodeField extends StatefulWidget {
  const MfaCodeField({
    super.key,
    required this.controller,
    required this.kind,
    required this.label,
    required this.instruction,
    this.errorText,
    this.onCompleted,
    this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final MfaCodeKind kind;

  /// The field's name, read by screen readers.
  final String label;

  /// The line above the boxes saying what to enter.
  final String instruction;

  /// Why the last code failed, shown under the boxes, which turn red.
  final String? errorText;

  /// Runs after a frame, so the filled boxes show before anything replaces
  /// them.
  final VoidCallback? onCompleted;
  final VoidCallback? onSubmitted;
  final bool autofocus;

  @override
  State<MfaCodeField> createState() => _MfaCodeFieldState();
}

class _MfaCodeFieldState extends State<MfaCodeField> {
  static const double _boxGap = 6;
  static const double _maxBoxWidth = 52;

  final _focusNode = FocusNode();
  late bool _wasComplete;

  bool get _isComplete => widget.controller.text.length == widget.kind.length;

  @override
  void initState() {
    super.initState();
    // A code already complete when the field appears is not sent again.
    _wasComplete = _isComplete;
    widget.controller.addListener(_handleTextChanged);
    _focusNode.addListener(_handleChanged);
  }

  @override
  void didUpdateWidget(MfaCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChanged);
      widget.controller.addListener(_handleTextChanged);
      _wasComplete = _isComplete;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleTextChanged() {
    _handleChanged();
    final complete = _isComplete;
    if (complete && !_wasComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isComplete) {
          widget.onCompleted?.call();
        }
      });
    }
    _wasComplete = complete;
  }

  List<TextInputFormatter> get _formatters => [
    TextInputFormatter.withFunction((oldValue, newValue) {
      final text = widget.kind.normalize(newValue.text);
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }),
  ];

  Widget _buildInput() {
    final isTotp = widget.kind == MfaCodeKind.totp;
    final keyboardType = isTotp
        ? TextInputType.number
        : TextInputType.visiblePassword;
    final autofillHints = isTotp ? const [AutofillHints.oneTimeCode] : null;
    void onSubmitted(String _) => widget.onSubmitted?.call();

    if (PlatformUtils.isApplePlatform) {
      return CupertinoTextField(
        controller: widget.controller,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.characters,
        autofillHints: autofillHints,
        autocorrect: false,
        enableSuggestions: false,
        inputFormatters: _formatters,
        onSubmitted: onSubmitted,
        decoration: null,
        showCursor: false,
      );
    }
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.characters,
      autofillHints: autofillHints,
      autocorrect: false,
      enableSuggestions: false,
      inputFormatters: _formatters,
      onSubmitted: onSubmitted,
      decoration: const InputDecoration.collapsed(hintText: null),
      showCursor: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final text = widget.controller.text;
    final activeIndex = _focusNode.hasFocus
        ? (text.length < kind.length ? text.length : kind.length - 1)
        : -1;

    final row = <Widget>[];
    for (var i = 0; i < kind.length; i++) {
      if (i > 0 && i % kind.groupSize == 0) {
        row.add(
          kind == MfaCodeKind.backupCode
              ? const _GroupDash()
              : const SizedBox(width: UIConstants.paddingStandard),
        );
      } else if (i > 0) {
        row.add(const SizedBox(width: _boxGap));
      }
      row.add(
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxBoxWidth),
            child: AspectRatio(
              aspectRatio: 0.85,
              child: _CodeBox(
                character: i < text.length ? text[i] : '',
                active: i == activeIndex,
                error: widget.errorText != null,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: UIConstants.paddingMedium),
          child: _Instruction(widget.instruction),
        ),
        Stack(
          children: [
            // The boxes only mirror the input below, for sighted users.
            ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row,
              ),
            ),
            // The real input covers the boxes, so tapping them focuses it
            // and autofill and paste reach it, but it is never painted.
            // Screen readers still reach it: a transparent Opacity would
            // otherwise drop its value and editing actions.
            Positioned.fill(
              child: Semantics(
                label: widget.label,
                child: Opacity(
                  opacity: 0,
                  alwaysIncludeSemantics: true,
                  child: _buildInput(),
                ),
              ),
            ),
          ],
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: UIConstants.paddingCompact),
            child: Semantics(
              liveRegion: true,
              child: _ErrorText(widget.errorText!),
            ),
          ),
      ],
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isApplePlatform) {
      return Text(
        text,
        style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
          color: CupertinoDynamicColor.resolve(
            CupertinoColors.systemRed,
            context,
          ),
          fontSize: 13,
        ),
      );
    }
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.error,
      ),
    );
  }
}

class _Instruction extends StatelessWidget {
  const _Instruction(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isApplePlatform) {
      return Text(
        text,
        style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
          color: CupertinoDynamicColor.resolve(
            CupertinoColors.secondaryLabel,
            context,
          ),
          fontSize: 15,
        ),
      );
    }
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _GroupDash extends StatelessWidget {
  const _GroupDash();

  @override
  Widget build(BuildContext context) {
    final color = PlatformUtils.isApplePlatform
        ? CupertinoDynamicColor.resolve(CupertinoColors.secondaryLabel, context)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: UIConstants.paddingSmall),
      child: Text('–', style: TextStyle(fontSize: 20, color: color)),
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({
    required this.character,
    required this.active,
    required this.error,
  });

  final String character;
  final bool active;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final Color fill;
    final Color border;
    final Color activeBorder;
    final Color errorBorder;
    final TextStyle textStyle;

    if (PlatformUtils.isApplePlatform) {
      final theme = CupertinoTheme.of(context);
      fill = CupertinoDynamicColor.resolve(
        CupertinoColors.secondarySystemGroupedBackground,
        context,
      );
      border = CupertinoDynamicColor.resolve(
        CupertinoColors.separator,
        context,
      );
      activeBorder = theme.primaryColor;
      errorBorder = CupertinoDynamicColor.resolve(
        CupertinoColors.systemRed,
        context,
      );
      textStyle = theme.textTheme.textStyle;
    } else {
      final theme = Theme.of(context);
      fill = Colors.transparent;
      border = theme.colorScheme.outline;
      activeBorder = theme.colorScheme.primary;
      errorBorder = theme.colorScheme.error;
      textStyle = theme.textTheme.titleLarge ?? const TextStyle();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: error
              ? errorBorder
              : active
              ? activeBorder
              : border,
          width: active ? 2 : 1,
        ),
      ),
      child: Center(
        child: Text(
          character,
          style: textStyle.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
