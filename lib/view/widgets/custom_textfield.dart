import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Widget myFieldAdvance({
  required BuildContext context,
  required TextEditingController controller,
  required String hintText,
  required TextInputType inputType,
  required TextInputAction textInputAction,
  required Color fillColor,
  required Color textBack,
  List<String>? autofillHints,
  List<TextInputFormatter>? inputFormatters,
  FocusNode? focusNode,
  FocusNode? nextFocusNode,
  bool? readOnly,
  bool showPasswordToggle = false, // Optional parameter for password toggle
  Function(String)? onChanged,
}) {
  final FocusNode internalFocusNode = FocusNode();
  const readOnlyMain = false;
  bool obscureText =
      showPasswordToggle; // Initially obscure if it's a password field

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SizedBox(
        height: 50,
        width: MediaQuery.of(context).size.width,
        child: StatefulBuilder(
          builder: (context, setState) {
            return TextFormField(
              inputFormatters: inputFormatters,
              readOnly: readOnly ?? readOnlyMain,
              onChanged: onChanged,
              controller: controller,
              autofillHints: autofillHints,
              textInputAction: textInputAction,
              keyboardType: inputType,
              obscureText: showPasswordToggle ? obscureText : false,
              focusNode: focusNode ?? internalFocusNode,
              onFieldSubmitted: (value) {
                if (nextFocusNode != null) {
                  FocusScope.of(context).requestFocus(nextFocusNode);
                } else {
                  FocusScope.of(context)
                      .unfocus(); // This dismisses the keyboard
                }
              },
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                label: Text(
                  hintText,
                  style: TextStyle(
                    backgroundColor: textBack,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    fontFamily: 'Outfit',
                  ),
                ),
                contentPadding:
                    const EdgeInsets.only(top: 3, left: 20, right: 12),
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: "Outfit",
                  color: Colors.grey,
                  decoration: TextDecoration.none,
                  wordSpacing: 1.2,
                ),
                filled: true,
                fillColor: fillColor,
                enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 1.2),
                    borderRadius: BorderRadius.all(Radius.circular(28))),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(28)),
                ),
                suffixIcon: showPasswordToggle
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: IconButton(
                          icon: Icon(
                            obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              obscureText = !obscureText;
                            });
                          },
                        ),
                      )
                    : null,
              ),
            );
          },
        ),
      ),
    ],
  );
}

// Example color constants (replace with your own)
class MyColors1 {
  static const Color textBlack = Colors.black;
  static const Color textWhite = Colors.white;
}
