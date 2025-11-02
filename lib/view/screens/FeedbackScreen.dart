import 'dart:developer';
import 'package:custom_rating_bar/custom_rating_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:swopband/controller/user_controller/UserController.dart';

class FeedbackPopup extends StatefulWidget {
  const FeedbackPopup({super.key});

  @override
  State<FeedbackPopup> createState() => _FeedbackPopupState();
}

class _FeedbackPopupState extends State<FeedbackPopup> {
  double _rating = 0;
  final TextEditingController _controller = TextEditingController();
  final controller = Get.put(UserController());

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Text(

                    "With your feedback, we can\nmake SwopBand even better!",
                    style: TextStyle(color: Colors.white, fontSize: 16,                    fontFamily: "Outfit",
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, color: Colors.white, size: 30),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RatingBar(emptyColor: Colors.white,

                   size: 40,
                  filledColor: Colors.white,
                  filledIcon: Icons.star,
                  emptyIcon: Icons.star_border,
                  onRatingChanged: (value) {
                    setState(() => _rating = value);
                  },
                  initialRating: 0,
                  maxRating: 5,
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(

                  hintText: "Type feedback here...",
                  hintStyle: TextStyle(color: Colors.grey,                    fontFamily: "Outfit",
                  ),
                  contentPadding: EdgeInsets.all(12),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Obx(() => controller.reviewLoader.value
                ? const CupertinoActivityIndicator(color: Colors.white)
                : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 50, vertical: 15),
              ),
              onPressed: () {
                final rating = _rating.toInt();
                log("Rating: $rating");
                log("Feedback: ${_controller.text}");
                controller.submitReviewRating(
                    rating, _controller.text, context);
              },
              child: const Text("Submit",style: TextStyle(                    fontFamily: "Outfit",
              ),),
            )),
          ],
        ),
      ),
    );
  }


}
