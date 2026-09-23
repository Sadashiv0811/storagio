import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:storagio/core/constants/static_values.dart';
import 'package:storagio/inventory/item/m_item.dart';

// ################ Shadow Related Widgets ################
class CustomInnerShadow extends StatelessWidget {
  /// A widget that applies an inner shadow to its child based on the A-B-C-D logic.

  final Widget child;
  final Color shadowColor;
  final double blur;
  final Offset offset;
  final BorderRadius borderRadius;

  const CustomInnerShadow({
    super.key,
    required this.child,
    required this.shadowColor,
    required this.blur,
    required this.offset,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius, // Layer B & D: The Inner Mask / Clipping
      child: CustomPaint(
        foregroundPainter: _InnerShadowPainter(
          shadowColor: shadowColor,
          blur: blur,
          offset: offset,
          borderRadius: borderRadius,
        ),
        child: child,
      ),
    );
  }
}

class _InnerShadowPainter extends CustomPainter {
  final Color shadowColor;
  final double blur;
  final Offset offset;
  final BorderRadius borderRadius;

  _InnerShadowPainter({
    required this.shadowColor,
    required this.blur,
    required this.offset,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    // Layer C: Creating the Shadow Blur
    // We create a path larger than the area and "subtract" the inner shape
    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);

    final shadowPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect.inflate(blur * 2)) // Larger outer boundary
      ..addRRect(rrect.shift(offset)); // The "hole" shifted by the offset

    // Apply the drawing
    canvas.save();
    canvas.clipRRect(rrect); // Ensures shadow stays inside (Layer D)
    canvas.drawPath(shadowPath, shadowPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_InnerShadowPainter oldDelegate) => true;
}

// ################ Input Field Related Widgets ################
class CLabel extends StatelessWidget {
  final String text;
  final double fontsize;
  final bool requiredField;
  final bool lowOpacity;
  const CLabel({
    super.key,
    required this.text,
    this.fontsize = 12,
    this.requiredField = false,
    this.lowOpacity = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 3),
      child: Opacity(
        opacity: lowOpacity ? 0.4 : 1,
        child: Row(
          crossAxisAlignment: .start,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: fontsize,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                letterSpacing: 0.5,
              ),
            ),
            if (requiredField) ...[
              SizedBox(width: 2),
              Text("*", style: TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}

class CDropDown extends StatelessWidget {
  final String? value;
  final String type;
  final List<String> valueList;
  final ValueChanged<String?> onChanged;

  const CDropDown({
    super.key,
    this.value,
    required this.type,
    required this.valueList,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    String hint = '';
    IconData icon = Icons.room;
    switch (type) {
      case "ROOM":
        hint = "Select Room";
        icon = Icons.room;
        break;
      case "CATEGORY":
        hint = "Select Category";
        icon = Icons.category_rounded;
        break;
      case "UNIT":
        hint = "Select Unit";
        icon = Icons.straighten;
        break;
      default:
    }

    return SizedBox(
      height: 55,
      child: Card(
        margin: EdgeInsets.zero,
        color: Theme.of(context).colorScheme.surface,
        shadowColor: Theme.of(context).colorScheme.shadow,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.blueGrey,
              ),
              items: valueList.map((value) {
                return DropdownMenuItem(
                  value: value,
                  child: Text(value, style: const TextStyle(fontSize: 15)),
                );
              }).toList(),
              onChanged: onChanged,
              hint: Row(
                children: [
                  Icon(icon, color: Colors.blueGrey.shade300),
                  const SizedBox(width: 12),
                  Text(
                    hint,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontSize: 15),
                  ),
                ],
              ),
              selectedItemBuilder: (context) {
                return valueList.map((value) {
                  return Row(
                    children: [
                      Icon(icon, color: Colors.blueGrey.shade300),
                      const SizedBox(width: 12),
                      Text(
                        value,
                        overflow: .ellipsis,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}

class SearchBarWidget extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final void Function(String) onChanged;
  final VoidCallback onTextClear;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onTextClear,
  });

  @override
  Widget build(BuildContext context) {
    return CustomInnerShadow(
      shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.3),
      blur: 5,
      offset: const Offset(0, 3),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: TextFormField(
          onChanged: onChanged,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          controller: controller,
          cursorColor: Theme.of(context).colorScheme.secondary,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]')),
          ],
          decoration: InputDecoration(
            fillColor: Theme.of(context).colorScheme.surface,
            hintText: hintText,
            hintStyle: TextStyle(color: Color(0xFF8E9199)),
            prefixIcon: Icon(Icons.search, color: Colors.blueGrey.shade300),
            suffixIcon: controller.text.trim().isEmpty
                ? null
                : IconButton(
                    icon: Icon(Icons.close, color: Colors.blueGrey.shade300),
                    onPressed: onTextClear,
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }
}

class CTextFormField extends StatelessWidget {
  final IconData? prefixIconData;
  final String hint;
  final IconData? suffixIcon;
  final VoidCallback? onTap;
  final bool multiline;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType keyboardType;

  const CTextFormField({
    super.key,
    this.prefixIconData,
    required this.hint,
    this.suffixIcon,
    this.onTap,
    this.multiline = false,
    this.validator,
    this.inputFormatters,
    this.controller,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: controller?.text,
      validator: validator,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔲 Shadow Container
            Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(18),
              shadowColor: Theme.of(context).colorScheme.shadow,
              child: TextFormField(
                controller: controller,
                onTap: onTap,
                cursorColor: Theme.of(context).colorScheme.secondary,
                readOnly: onTap != null,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                keyboardType: multiline
                    ? TextInputType.multiline
                    : keyboardType,
                maxLines: multiline ? null : 1,
                inputFormatters: inputFormatters,

                // 🔥 Hook into FormField state
                onChanged: (value) {
                  field.didChange(value);
                },

                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  hintText: hint,

                  errorText: null,
                  errorStyle: const TextStyle(height: 0),
                  hintStyle: TextStyle(color: Color(0xFF8E9199)),

                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.lightBlueAccent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  prefixIcon: prefixIconData != null
                      ? Icon(prefixIconData, color: Colors.blueGrey.shade300)
                      : null,
                  suffixIcon: suffixIcon != null
                      ? Icon(
                          suffixIcon,
                          color: Colors.blueGrey.shade300,
                          size: 18,
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),

            // Error OUTSIDE (only when Form.validate() is called)
            if (field.hasError) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class PasswordTextField extends StatelessWidget {
  final IconData prefixIcon;
  final bool obscureText;
  final VoidCallback toggleVisibility;
  final String? Function(String?)? validator;
  final TextEditingController controller;

  const PasswordTextField({
    super.key,
    required this.prefixIcon,
    required this.obscureText,
    required this.toggleVisibility,
    this.validator,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return FormField(
      validator: validator,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(18),
              shadowColor: Theme.of(context).colorScheme.shadow,
              child: TextFormField(
                controller: controller,
                obscureText: obscureText,
                cursorColor: Theme.of(context).colorScheme.secondary,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                keyboardType: TextInputType.visiblePassword,

                onChanged: (value) {
                  field.didChange(value);
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  hintText: 'abc321xyz',
                  prefixIcon: Icon(prefixIcon, color: Colors.blueGrey.shade300),
                  suffixIcon: InkWell(
                    onTap: toggleVisibility,
                    child: Icon(
                      obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.blueGrey.shade300,
                    ),
                  ),
                  errorText: null,
                  errorStyle: const TextStyle(height: 0),
                  hintStyle: TextStyle(color: Color(0xFF8E9199)),

                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.lightBlueAccent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),

            // Error OUTSIDE (only when Form.validate() is called)
            if (field.hasError) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ################ Header / Title, Footer Widgets ################
class AppBarTitle extends StatelessWidget {
  const AppBarTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      "Storagio",
      style: TextStyle(
        color: isDark ? Color.fromARGB(255, 56, 192, 255) : Color(0xFF1E3A8A),
        fontWeight: FontWeight.bold,
        fontSize: 25,
      ),
    );
  }
}

class HeaderSection extends StatelessWidget {
  final String title;
  final String message;
  const HeaderSection({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class DialogHeader extends StatelessWidget {
  final String title;
  final String? message;
  const DialogHeader({super.key, required this.title, this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(
            textAlign: TextAlign.center,
            message!,
            style: TextStyle(
              color: isDark ? Colors.grey.shade300 : Color(0xFF44474E),
              height: 1.2,
              fontSize: 15,
            ),
          ),
        ],
      ],
    );
  }
}

class FooterSection extends StatelessWidget {
  final String message;
  final String btnText;
  final VoidCallback callback;
  const FooterSection({
    super.key,
    required this.message,
    required this.btnText,
    required this.callback,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          message,
          style: TextStyle(
            color: isDark ? Colors.white : Color(0xFF3F474E),
            fontSize: 16,
          ),
        ),
        GestureDetector(
          onTap: callback,
          child: Text(
            btnText,
            style: TextStyle(
              color: isDark
                  ? Color.fromARGB(255, 56, 192, 255)
                  : Color(0xFF005C9E),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

// ################ Other Widgets ################
class CTile extends StatelessWidget {
  final String uniqueKey;
  final bool isSelected;
  final String title;
  final String? subtitle;
  final int color;
  final String icon;
  final VoidCallback onTap;

  const CTile({
    super.key,
    required this.isSelected,
    required this.title,
    this.subtitle,
    required this.color,
    required this.icon,
    required this.onTap,
    required this.uniqueKey,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(12),
      ),
      child: Container(
        margin: EdgeInsets.all(3),
        decoration: isSelected
            ? BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondary,
                  width: 3.0,
                ),
                borderRadius: BorderRadiusGeometry.circular(12),
              )
            : null,

        child: ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(color),
            ),
            child: Icon(
              IconData(int.parse(icon), fontFamily: 'MaterialIcons'),
              size: 23,
            ),
          ),
          title: Text(
            title,
            overflow: .ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: subtitle != null
              ? Text(subtitle!, style: Theme.of(context).textTheme.bodySmall)
              : null,
          trailing: isSelected
              ? Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                )
              : null,
        ),
      ),
    );
  }
}

class WarningIcon extends StatelessWidget {
  const WarningIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 4,
            spreadRadius: 3,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.warning_amber_rounded,
        color: Color(0xFFC62828),
        size: 50,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionText;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: .min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.lightBlueAccent.withValues(alpha: 0.1)
                : const Color(0xFF0056D2).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 64,
            color: isDark ? Colors.lightBlueAccent : Color(0xFF0056D2),
          ),
        ),

        const SizedBox(height: 24),

        Text(
          title,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: 28),

        if (actionText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.lightBlueAccent.withValues(alpha: 0.1)
                  : const Color(0xFF0056D2).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.lightBlueAccent.withValues(alpha: 0.2)
                    : const Color(0xFF0056D2).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.touch_app_outlined,
                  color: isDark ? Colors.lightBlueAccent : Color(0xFF0056D2),
                ),

                SizedBox(width: 10),

                Text(
                  actionText.toString(),
                  textAlign: .center,
                  style: TextStyle(
                    color: isDark ? Colors.lightBlueAccent : Color(0xFF0056D2),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class EmptyRooms extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback addCallback;
  final double titleFontSize;
  final double topPadding;
  final bool isRequired;
  const EmptyRooms({
    super.key,
    required this.title,
    required this.message,
    required this.addCallback,
    this.titleFontSize = 12,
    this.topPadding = 20,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              CLabel(
                text: title,
                fontsize: titleFontSize,
                requiredField: isRequired,
              ),

              IconButton(onPressed: addCallback, icon: Icon(Icons.add)),
            ],
          ),
          Text(
            message,
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class DeleteRecord extends StatelessWidget {
  final String title;
  final String message;
  final String? positiveText, negativeText;
  const DeleteRecord({
    super.key,
    required this.title,
    required this.message,
    this.positiveText,
    this.negativeText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),

      title: Column(
        children: [
          Icon(Icons.warning_rounded, color: Colors.red, size: 50),

          Text(title, softWrap: true),
        ],
      ),

      content: Text(message),

      actions: [
        TextButton.icon(
          onPressed: () {
            Navigator.pop(context, false);
          },
          icon: Icon(
            Icons.close,
            color: isDark ? Colors.grey.shade200 : Color(0xFF44474E),
          ),
          label: Text(
            negativeText ?? 'Cancel',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey.shade200 : Color(0xFF44474E),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),

          onPressed: () {
            Navigator.pop(context, true);
          },

          icon: Icon(
            positiveText != null ? Icons.notifications_off : Icons.delete,
          ),

          label: Text(
            positiveText ?? "Delete",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

class LoadingDisplay extends StatelessWidget {
  const LoadingDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class ErrorDisplay extends StatelessWidget {
  final Object error;
  final StackTrace stack;
  const ErrorDisplay({super.key, required this.error, required this.stack});

  @override
  Widget build(BuildContext context) {
    logger.e(error, stackTrace: stack);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          textAlign: TextAlign.center,
          kDebugMode
              ? error.toString()
              : 'Something went wrong. Please try again.',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class ImagePlaceHolder extends StatelessWidget {
  final double size;
  const ImagePlaceHolder({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: size,
      width: size,
      color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.2),
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 30,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}

class FieldsDisplayRow extends StatelessWidget {
  final String title;
  final String value;
  final double? fontSize;
  final Color? valueColor;

  const FieldsDisplayRow({
    super.key,
    required this.title,
    required this.value,
    this.valueColor,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: fontSize ?? 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize ?? 14,
            fontWeight: fontSize == null ? FontWeight.bold : FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class CategoryNameChip extends StatelessWidget {
  final String categoryName;
  final Color bgColor;
  const CategoryNameChip({
    super.key,
    required this.categoryName,
    this.bgColor = Colors.blueAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: .min,
        children: [
          const Icon(Icons.category_rounded, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            categoryName,
            overflow: .ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// Displays Paid On, Last Payment Amount, Due Date
class BillsRechargesFields extends StatelessWidget {
  final MItem item;
  const BillsRechargesFields({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        // Paid On
        FieldsDisplayRow(
          title: "Paid On",
          value: DateFormat("dd MMM yyyy").format(item.purchaseDate!),
          fontSize: 12,
          valueColor: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
        ),
        const SizedBox(height: 4),

        // Last Payment Amount
        FieldsDisplayRow(
          title: "Last Payment Amount",
          value: "Rs. ${item.lastPaymentAmount}",
        ),
        const SizedBox(height: 4),

        // Due Date
        FieldsDisplayRow(
          title: "Due Date",
          value: DateFormat("dd MMM yyyy").format(item.warrantyExpiry!),
          valueColor: Colors.redAccent,
        ),
      ],
    );
  }
}

// ################ BottomSheet Widgets ################
class BSHandle extends StatelessWidget {
  const BSHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class BSHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const BSHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        Column(
          mainAxisSize: .min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.lightBlueAccent : Color(0xFF1E40AF),
              ),
            ),
            SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.close, size: 24),
        ),
      ],
    );
  }
}

// ################ Button Widgets ################
class CPositiveButton extends StatelessWidget {
  final String text;
  final VoidCallback callback;
  final IconData? iconData;
  final Color? bgColor;
  const CPositiveButton({
    super.key,
    required this.text,
    required this.callback,
    this.iconData,
    this.bgColor = const Color(0xFF005FB0),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ElevatedButton.icon(
      onPressed: callback,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 4,
        shadowColor: isDark ? Colors.lightBlueAccent : Colors.grey,
      ),
      icon: Icon(iconData, color: Colors.white),
      label: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}

class CCancelButton extends StatelessWidget {
  const CCancelButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextButton.icon(
      onPressed: () => Navigator.pop(context),
      icon: Icon(
        Icons.close,
        color: isDark ? Colors.grey.shade200 : Color(0xFF44474E),
      ),
      label: Text(
        'Cancel',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isDark ? Colors.grey.shade200 : Color(0xFF44474E),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

// ################ Function ################
final GlobalKey<ScaffoldMessengerState> snackbarKey =
    GlobalKey<ScaffoldMessengerState>();

void showSnackBar(String message, {Color backgroundColor = Colors.green}) {
  snackbarKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      duration: const Duration(seconds: 2),
    ),
  );
}

Text appBarText(String title) {
  return Text(
    title,
    maxLines: 1,
    overflow: .ellipsis,
    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
  );
}

