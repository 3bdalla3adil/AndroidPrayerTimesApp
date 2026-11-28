import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' as material;

/// Platform-native controls shared by feature screens.
/// iOS uses Cupertino widgets; Android uses Material 3 widgets.
bool get useCupertino => defaultTargetPlatform == TargetPlatform.iOS;

class AdaptiveListSection extends StatelessWidget {
  const AdaptiveListSection.insetGrouped({
    super.key,
    this.header,
    this.footer,
    required this.children,
  });

  final Widget? header;
  final Widget? footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (useCupertino) {
      return cupertino.CupertinoListSection.insetGrouped(
        header: header,
        footer: footer,
        children: children,
      );
    }
    return material.Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: DefaultTextStyle(
                style: material.Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: material.Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
                child: header!,
              ),
            ),
          ...children,
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
              child: DefaultTextStyle(
                style: material.Theme.of(context).textTheme.bodySmall!,
                child: footer!,
              ),
            ),
        ],
      ),
    );
  }
}

class AdaptiveListTile extends StatelessWidget {
  const AdaptiveListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.backgroundColor,
    this.additionalInfo,
  });

  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Widget? additionalInfo;

  @override
  Widget build(BuildContext context) {
    if (useCupertino) {
      return cupertino.CupertinoListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
        backgroundColor: backgroundColor,
        additionalInfo: additionalInfo,
      );
    }
    return material.ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing ?? additionalInfo,
      onTap: onTap,
      tileColor: backgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
    );
  }
}

class AdaptiveButton extends StatelessWidget {
  const AdaptiveButton({
    super.key,
    this.padding,
    this.color,
    this.minimumSize,
    this.borderRadius,
    required this.onPressed,
    required this.child,
  }) : _filled = false;

  const AdaptiveButton.filled({
    super.key,
    this.padding,
    this.color,
    this.minimumSize,
    this.borderRadius,
    required this.onPressed,
    required this.child,
  }) : _filled = true;

  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Size? minimumSize;
  final BorderRadius? borderRadius;
  final VoidCallback? onPressed;
  final Widget child;
  final bool _filled;

  @override
  Widget build(BuildContext context) {
    if (useCupertino) {
      final buttonColor = color;
      if (_filled) {
        return cupertino.CupertinoButton.filled(
          padding: padding,
          borderRadius: borderRadius,
          minSize: minimumSize?.height,
          onPressed: onPressed,
          child: child,
        );
      }
      return cupertino.CupertinoButton(
        padding: padding,
        color: buttonColor,
        borderRadius: borderRadius,
        minSize: minimumSize?.height ?? 44,
        onPressed: onPressed,
        child: child,
      );
    }
    final shape = material.RoundedRectangleBorder(
      borderRadius: borderRadius ?? BorderRadius.circular(14),
    );
    final style = material.ButtonStyle(
      padding: material.WidgetStatePropertyAll(
        padding ?? const EdgeInsets.symmetric(horizontal: 16),
      ),
      minimumSize: material.WidgetStatePropertyAll(
        minimumSize ?? const Size(64, 48),
      ),
      backgroundColor: color == null ? null : material.WidgetStatePropertyAll(color),
      shape: material.WidgetStatePropertyAll(shape),
    );
    return (_filled || color != null)
        ? material.FilledButton(
            onPressed: onPressed,
            style: style,
            child: child,
          )
        : material.TextButton(
            onPressed: onPressed,
            style: style,
            child: child,
          );
  }
}

class AdaptiveSwitch extends StatelessWidget {
  const AdaptiveSwitch({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => useCupertino
      ? cupertino.CupertinoSwitch(value: value, onChanged: onChanged)
      : material.Switch(value: value, onChanged: onChanged);
}

class AdaptiveActivityIndicator extends StatelessWidget {
  const AdaptiveActivityIndicator({super.key, this.color});
  final Color? color;

  @override
  Widget build(BuildContext context) => useCupertino
      ? cupertino.CupertinoActivityIndicator(color: color)
      : material.SizedBox(
          width: 24,
          height: 24,
          child: material.CircularProgressIndicator(
            strokeWidth: 2.6,
            color: color,
          ),
        );
}

class AdaptiveTextField extends StatelessWidget {
  const AdaptiveTextField({
    super.key,
    this.controller,
    this.keyboardType,
    this.textAlign = TextAlign.start,
    this.placeholder,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextAlign textAlign;
  final String? placeholder;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => useCupertino
      ? cupertino.CupertinoTextField(
          controller: controller,
          keyboardType: keyboardType,
          textAlign: textAlign,
          placeholder: placeholder,
          autofocus: autofocus,
        )
      : material.TextField(
          controller: controller,
          keyboardType: keyboardType,
          textAlign: textAlign,
          autofocus: autofocus,
          decoration: material.InputDecoration(
            hintText: placeholder,
            border: const material.OutlineInputBorder(),
            isDense: true,
          ),
        );
}

class AdaptiveSearchField extends StatelessWidget {
  const AdaptiveSearchField({super.key, this.placeholder, this.onChanged});
  final String? placeholder;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => useCupertino
      ? cupertino.CupertinoSearchTextField(
          placeholder: placeholder,
          onChanged: onChanged,
        )
      : material.SearchBar(
          hintText: placeholder,
          onChanged: onChanged,
          leading: const material.Icon(material.Icons.search),
          padding: const material.WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16),
          ),
        );
}

class AdaptiveSlider extends StatelessWidget {
  const AdaptiveSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int? divisions;

  @override
  Widget build(BuildContext context) => useCupertino
      ? cupertino.CupertinoSlider(
          min: min,
          max: max,
          value: value,
          divisions: divisions,
          onChanged: onChanged,
        )
      : material.Slider(
          min: min,
          max: max,
          value: value.clamp(min, max),
          divisions: divisions,
          onChanged: onChanged,
        );
}

/// Determinate progress that follows the platform's native visual language.
class AdaptiveLinearProgressIndicator extends StatelessWidget {
  const AdaptiveLinearProgressIndicator({
    super.key,
    required this.value,
    this.minHeight = 4,
    this.backgroundColor,
    this.valueColor,
  });

  final double value;
  final double minHeight;
  final Color? backgroundColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final progress = value.clamp(0.0, 1.0).toDouble();
    if (!useCupertino) {
      return material.LinearProgressIndicator(
        value: progress,
        minHeight: minHeight,
        backgroundColor: backgroundColor,
        valueColor: valueColor == null
            ? null
            : material.AlwaysStoppedAnimation<Color>(valueColor!),
      );
    }

    final trackColor = backgroundColor ??
        cupertino.CupertinoColors.systemGrey5.resolveFrom(context);
    final progressColor = valueColor ?? cupertino.CupertinoTheme.of(context).primaryColor;
    return Semantics(
      label: 'Progress',
      value: '${(progress * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(minHeight / 2),
        child: SizedBox(
          height: minHeight,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: trackColor),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: progress,
                  child: ColoredBox(color: progressColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdaptiveAlertDialog extends StatelessWidget {
  const AdaptiveAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions = const [],
  });

  final Widget? title;
  final Widget? content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => useCupertino
      ? cupertino.CupertinoAlertDialog(
          title: title,
          content: content,
          actions: actions,
        )
      : material.AlertDialog(
          title: title,
          content: content,
          actions: actions,
        );
}

class AdaptiveDialogAction extends StatelessWidget {
  const AdaptiveDialogAction({
    super.key,
    this.isDestructiveAction = false,
    this.isDefaultAction = false,
    required this.onPressed,
    required this.child,
  });

  final bool isDestructiveAction;
  final bool isDefaultAction;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (useCupertino) {
      return cupertino.CupertinoDialogAction(
        isDestructiveAction: isDestructiveAction,
        isDefaultAction: isDefaultAction,
        onPressed: onPressed,
        child: child,
      );
    }
    final button = isDestructiveAction
        ? material.TextButton(
            onPressed: onPressed,
            style: material.TextButton.styleFrom(
              foregroundColor: material.Theme.of(context).colorScheme.error,
            ),
            child: child,
          )
        : isDefaultAction
            ? material.FilledButton(onPressed: onPressed, child: child)
            : material.TextButton(onPressed: onPressed, child: child);
    return button;
  }
}

class AdaptiveActionSheetAction extends StatelessWidget {
  const AdaptiveActionSheetAction({
    super.key,
    this.isDefaultAction = false,
    required this.onPressed,
    required this.child,
  });

  final bool isDefaultAction;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) => useCupertino
      ? cupertino.CupertinoActionSheetAction(
          isDefaultAction: isDefaultAction,
          onPressed: onPressed,
          child: child,
        )
      : material.ListTile(
          title: DefaultTextStyle(
            style: material.Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: isDefaultAction
                  ? material.Theme.of(context).colorScheme.primary
                  : null,
            ),
            child: child,
          ),
          onTap: onPressed,
        );
}

class AdaptiveActionSheet extends StatelessWidget {
  const AdaptiveActionSheet({
    super.key,
    this.title,
    this.message,
    this.actions = const [],
    this.cancelButton,
  });

  final Widget? title;
  final Widget? message;
  final List<Widget> actions;
  final Widget? cancelButton;

  @override
  Widget build(BuildContext context) {
    if (useCupertino) {
      return cupertino.CupertinoActionSheet(
        title: title,
        message: message,
        actions: actions,
        cancelButton: cancelButton,
      );
    }
    return material.SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: DefaultTextStyle(
                style: material.Theme.of(context).textTheme.titleMedium!,
                child: title!,
              ),
            ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: DefaultTextStyle(
                style: material.Theme.of(context).textTheme.bodySmall!,
                child: message!,
              ),
            ),
          ...actions,
          if (cancelButton != null) ...[
            const material.Divider(height: 1),
            cancelButton!,
          ],
        ],
      ),
    );
  }
}

Future<T?> showAdaptiveDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return useCupertino
      ? cupertino.showCupertinoDialog<T>(
          context: context,
          builder: builder,
          barrierDismissible: barrierDismissible,
        )
      : material.showDialog<T>(
          context: context,
          builder: builder,
          barrierDismissible: barrierDismissible,
        );
}

Future<T?> showAdaptiveModalPopup<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return useCupertino
      ? cupertino.showCupertinoModalPopup<T>(context: context, builder: builder)
      : material.showModalBottomSheet<T>(
          context: context,
          builder: builder,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
        );
}

class AdaptivePicker extends StatefulWidget {
  const AdaptivePicker({
    super.key,
    required this.itemExtent,
    required this.onSelectedItemChanged,
    required this.children,
    this.scrollController,
  });

  final double itemExtent;
  final FixedExtentScrollController? scrollController;
  final ValueChanged<int> onSelectedItemChanged;
  final List<Widget> children;

  @override
  State<AdaptivePicker> createState() => _AdaptivePickerState();
}

class _AdaptivePickerState extends State<AdaptivePicker> {
  late int _selected = (widget.scrollController?.initialItem ?? 0)
      .clamp(0, widget.children.length - 1);

  @override
  Widget build(BuildContext context) {
    if (useCupertino) {
      return cupertino.CupertinoPicker(
        itemExtent: widget.itemExtent,
        scrollController: widget.scrollController,
        onSelectedItemChanged: widget.onSelectedItemChanged,
        children: widget.children,
      );
    }
    return material.DropdownButton<int>(
      isExpanded: true,
      value: _selected,
      menuMaxHeight: 360,
      items: [
        for (var i = 0; i < widget.children.length; i++)
          material.DropdownMenuItem<int>(
            value: i,
            child: widget.children[i],
          ),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selected = value);
        widget.onSelectedItemChanged(value);
      },
    );
  }
}

/// Trailing chevron matching the active platform's list affordance.
class AdaptiveListTileChevron extends StatelessWidget {
  const AdaptiveListTileChevron({super.key});

  @override
  Widget build(BuildContext context) => useCupertino
      ? const cupertino.CupertinoListTileChevron()
      : const material.Icon(
          material.Icons.chevron_right,
          size: 22,
        );
}
