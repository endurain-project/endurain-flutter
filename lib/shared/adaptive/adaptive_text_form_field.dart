import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

class AdaptiveTextFormField extends StatelessWidget {
  const AdaptiveTextFormField({
    super.key,
    required this.label,
    this.placeholder,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
    this.obscureText = false,
    this.prefixIcon,
    this.suffix,
    this.autofillHints,
    this.autocorrect = true,
    this.enableSuggestions = true,
  });

  final String label;
  final String? placeholder;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffix;

  /// Autofill hints (e.g. [AutofillHints.username], [AutofillHints.password])
  /// so password managers such as Bitwarden can recognize and fill this
  /// field. The field should also be wrapped in an [AutofillGroup].
  final Iterable<String>? autofillHints;
  final bool autocorrect;
  final bool enableSuggestions;

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isApplePlatform) {
      final colorScheme = CupertinoTheme.of(context);
      final labelColor = CupertinoDynamicColor.resolve(
        CupertinoColors.secondaryLabel,
        context,
      );
      final fieldColor = CupertinoDynamicColor.resolve(
        CupertinoColors.secondarySystemGroupedBackground,
        context,
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: UIConstants.paddingSmall),
            child: Text(
              label.toUpperCase(),
              style: colorScheme.textTheme.textStyle.copyWith(
                color: labelColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fieldColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: CupertinoTextFormFieldRow(
                controller: controller,
                placeholder: placeholder,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                validator: validator,
                onFieldSubmitted: onFieldSubmitted,
                obscureText: obscureText,
                autofillHints: autofillHints,
                autocorrect: autocorrect,
                enableSuggestions: enableSuggestions,
                prefix: prefixIcon,
                padding: const EdgeInsets.symmetric(
                  horizontal: UIConstants.paddingStandard,
                  vertical: UIConstants.paddingMedium,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: placeholder,
        border: const OutlineInputBorder(),
        prefixIcon: prefixIcon,
        suffixIcon: suffix,
      ),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      obscureText: obscureText,
      autofillHints: autofillHints,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
    );
  }
}
