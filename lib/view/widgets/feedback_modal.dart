import 'dart:developer';
import 'package:custom_rating_bar/custom_rating_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:swopband/controller/user_controller/UserController.dart';

class FeedbackModal extends StatefulWidget {
  const FeedbackModal({super.key});

  @override
  State<FeedbackModal> createState() => _FeedbackModalState();
}

class _FeedbackModalState extends State<FeedbackModal> {
  double _rating = 0;
  final TextEditingController _controller = TextEditingController();
  final controller = Get.put(UserController());

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      shadowColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          // mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "With your feedback, we can\nmake SwopBand even better!",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Rating stars
            Align(
              alignment: Alignment.center,
              child: RatingBar(
                alignment: Alignment.center,
                filledIcon: Icons.star,
                filledColor: Colors.white,

                emptyIcon: Icons.star_border,
                onRatingChanged: (value) {
                  log("rating----->$value");
                  setState(() {
                    _rating = value;
                  });
                },
                initialRating: 0,
                maxRating: 5,
              ),
            ),
            const SizedBox(height: 16),

            // Feedback TextField
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: "Type feedback here...",
                  hintStyle: TextStyle(color: Colors.grey),
                  contentPadding: EdgeInsets.all(12),
                  border: InputBorder.none,
                ),
                onSubmitted: (value) {
                  FocusScope.of(context).unfocus();
                },
              ),
            ),

            const SizedBox(height: 20),

            // Submit button
            Obx(() => controller.reviewLoader.value
                ? const CupertinoActivityIndicator(color: Colors.white)
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 47, vertical: 12),
                    ),
                    onPressed: () {
                      final rating = int.tryParse(_rating.toString().substring(0, 1)) ?? 0;
                      log('Rating: $rating');
                      log('Feedback: ${_controller.text}');
                      controller.submitReviewRating(
                        rating, 
                        _controller.text, 
                        context,
                        onSuccess: () {
                          // Clear the form after successful API response
                          setState(() {
                            _rating = 0;
                            _controller.clear();
                          });
                        },
                      );
                    },
                    child: const Text("Submit"),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Helper function to show feedback modal
class FeedbackModalHelper {
  static void showFeedbackModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return const FeedbackModal();
      },
    );
  }
}
