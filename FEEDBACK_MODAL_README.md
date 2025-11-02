# Feedback Modal Implementation

This document explains how to use the feedback modal that overlays other pages as a popup in the SwopBand app.

## Overview

The feedback modal is a reusable widget that can be triggered from any screen to collect user feedback with a star rating and text input. It appears as a popup dialog that overlays the current screen content.

## Files Created

1. **`lib/view/widgets/feedback_modal.dart`** - The main feedback modal widget
2. **`lib/view/screens/feedback_example_screen.dart`** - Example screen showing how to use the modal
3. **Updated `lib/view/screens/SettingScreen.dart`** - Added feedback option to settings

## How to Use

### Basic Usage

To show the feedback modal from any screen, simply call:

```dart
FeedbackModalHelper.showFeedbackModal(context);
```

### Example Implementation

```dart
import 'package:swopband/view/widgets/feedback_modal.dart';

// In your widget's onPressed or onTap method:
ElevatedButton(
  onPressed: () {
    FeedbackModalHelper.showFeedbackModal(context);
  },
  child: Text("Give Feedback"),
)
```

### Features

- **Star Rating**: 5-star rating system using the `custom_rating_bar` package
- **Text Input**: Multi-line text field for detailed feedback
- **Close Button**: X button in the top-right corner to dismiss the modal
- **Submit Functionality**: Integrates with the existing `UserController.submitReviewRating()` method
- **Loading State**: Shows loading indicator while submitting feedback
- **Responsive Design**: Adapts to different screen sizes

### Modal Properties

- **Background**: Black with white text (matches app theme)
- **Shape**: Rounded corners (20px border radius)
- **Dismissible**: Can be closed by tapping outside or the close button
- **Overlay**: Semi-transparent background overlay

### Integration Points

The modal integrates with:
- `UserController` for submitting feedback
- Existing API service for sending feedback to backend
- App's color scheme and text styles

### Example Screens

1. **Settings Screen**: Added "Send Feedback" option in the account information section
2. **Example Screen**: Demonstrates multiple ways to trigger the modal

### Customization

You can customize the modal by modifying:
- Colors and styling in `FeedbackModal` widget
- Text content and labels
- Rating system (currently 5 stars)
- Input field properties (max lines, placeholder text, etc.)

### Dependencies

The modal uses these existing packages:
- `custom_rating_bar` for star rating
- `get` for state management
- `flutter/material.dart` for UI components

## Usage in Different Contexts

### From AppBar Actions
```dart
AppBar(
  actions: [
    IconButton(
      icon: Icon(Icons.feedback),
      onPressed: () => FeedbackModalHelper.showFeedbackModal(context),
    ),
  ],
)
```

### From Bottom Navigation
```dart
BottomNavigationBarItem(
  icon: Icon(Icons.star_border),
  label: 'Feedback',
  onTap: () => FeedbackModalHelper.showFeedbackModal(context),
)
```

### From Floating Action Button
```dart
FloatingActionButton(
  onPressed: () => FeedbackModalHelper.showFeedbackModal(context),
  child: Icon(Icons.feedback),
)
```

## Testing

To test the feedback modal:
1. Navigate to the Settings screen and tap "Send Feedback"
2. Or run the example screen: `FeedbackExampleScreen`
3. Try different rating values and text inputs
4. Test the close functionality
5. Verify the submit process works correctly

The modal is designed to be user-friendly and non-intrusive while providing a clear way for users to provide feedback about the app.
