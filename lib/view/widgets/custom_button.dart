import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final Color? buttonColor;
  final Color? textColor;
  final Color? border;
  final Widget? widget;
  final VoidCallback? onPressed;
  final bool isLoading;
  final TextStyle? textStyle;

  const CustomButton({
    required this.text,
    required this.onPressed,
    this.buttonColor,
    this.textColor,
    super.key,
    this.widget,
    this.border,
    this.isLoading = false,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveButtonColor = buttonColor ?? Colors.black;
    final Color effectiveTextColor = textColor ?? Colors.white;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: effectiveButtonColor,
        foregroundColor: effectiveTextColor,
        disabledBackgroundColor: effectiveButtonColor.withOpacity(0.6),
        disabledForegroundColor: effectiveTextColor.withOpacity(0.6),
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: border ?? Colors.transparent)),
      ),
      onPressed: isLoading ? null : onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget != null && !isLoading) ...[
            widget!,
            const SizedBox(width: 10),
          ],
          if (isLoading) ...[
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(effectiveTextColor),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Text(
            text,
            style: textStyle ??
                TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 15,
                  color: effectiveTextColor,
                  fontFamily: "Chromatica",
                ),
            textAlign: TextAlign.center,
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}
