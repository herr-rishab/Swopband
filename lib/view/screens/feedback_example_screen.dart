import 'package:flutter/material.dart';
import 'package:swopband/view/widgets/feedback_modal.dart';
import 'package:swopband/view/utils/app_text_styles.dart';

class FeedbackExampleScreen extends StatelessWidget {
  const FeedbackExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Feedback Modal Example',
          style: AppTextStyles.large.copyWith(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Example content that would be on your page
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.yellow,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your App Content',
                    style: AppTextStyles.large.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This is an example of your app content. The feedback modal will overlay this content when triggered.',
                    style: AppTextStyles.medium.copyWith(
                      color: Colors.grey[300],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Button to trigger feedback modal
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              onPressed: () {
                // This is how you show the feedback modal
                FeedbackModalHelper.showFeedbackModal(context);
              },
              child: const Text(
                "Give Feedback",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Additional example buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    FeedbackModalHelper.showFeedbackModal(context);
                  },
                  icon: const Icon(Icons.rate_review),
                  label: const Text("Rate App"),
                ),
                
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    FeedbackModalHelper.showFeedbackModal(context);
                  },
                  icon: const Icon(Icons.feedback),
                  label: const Text("Send Feedback"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
