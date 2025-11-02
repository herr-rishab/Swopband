import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:swopband/controller/link_controller/LinkController.dart';
import 'package:swopband/view/widgets/custom_button.dart';
import 'package:swopband/view/widgets/custom_snackbar.dart';
import 'package:swopband/view/widgets/custom_textfield.dart';
import '../translations/app_strings.dart';
import '../utils/images/iamges.dart';
import '../utils/app_text_styles.dart';
import '../utils/app_colors.dart';
import 'bottom_nav/BottomNavScreen.dart';

class AddLinkScreen extends StatefulWidget {
  const AddLinkScreen({super.key});

  @override
  State<AddLinkScreen> createState() => _AddLinkScreenState();
}

class _AddLinkScreenState extends State<AddLinkScreen> {
  final controller = Get.put(LinkController());

  @override
  void initState() {
    super.initState();
    controller.fetchLinks();
  }

  final List<TextEditingController> _linkControllers = [
    TextEditingController()
  ];
  final List<String> _linkTypes = ['instagram']; // Default first link type
  int _linkCount = 1;
  final List<FocusNode> _linkFocusNodes = [FocusNode()];

  // Supported link types without 'custom'
  final Map<String, Map<String, dynamic>> _supportedLinks = {
    'instagram': {'name': 'Instagram', 'icon': MyImages.insta},
    'snapchat': {'name': 'Snapchat', 'icon': MyImages.snapchat},
    'linkedin': {'name': 'LinkedIn', 'icon': MyImages.linkedId},
    'x': {'name': 'Twitter', 'icon': MyImages.xmaster},
    'spotify': {'name': 'Spotify', 'icon': MyImages.spotify},
    'facebook': {'name': 'Facebook', 'icon': MyImages.facebook},
    'strava': {'name': 'Strava', 'icon': MyImages.strava},
    'youtube': {'name': 'YouTube', 'icon': MyImages.youtube},
    'tiktok': {'name': 'TikTok', 'icon': MyImages.tiktok},
    'discord': {'name': 'Discord', 'icon': MyImages.discord},
    'phone': {'name': 'Phone', 'icon': MyImages.phone},
    'email': {'name': 'Email', 'icon': MyImages.email},
  };

  @override
  void dispose() {
    for (var controller in _linkControllers) {
      controller.dispose();
    }
    for (var focusNode in _linkFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _submitLinks() async {
    for (int i = 0; i < _linkControllers.length; i++) {
      if (_linkControllers[i].text.isEmpty || _linkTypes[i].isEmpty) {
        SnackbarUtil.showError(
            "Please select a link type and provide the link for item  ${i + 1}");
        return;
      }
    }

    try {
      for (int i = 0; i < _linkControllers.length; i++) {
        await controller.createLink(
          name: _linkTypes[i],
          type: _linkTypes[i],
          url: _linkControllers[i].text,
          call: () {},
        );
      }

      // Clear form
      for (var c in _linkControllers) {
        c.clear();
      }
      setState(() {
        _linkTypes.clear();
        _linkTypes.add('instagram');
        _linkControllers.clear();
        _linkControllers.add(TextEditingController());
        _linkFocusNodes.clear();
        _linkFocusNodes.add(FocusNode());
      });

      SnackbarUtil.showSuccess("Links submitted successfully!");
      Get.off(() => BottomNavScreen());
    } catch (e) {
      SnackbarUtil.showError("Failed to submit links: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 100,
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    // Header and supported links display
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            AppStrings.addLinks.tr,
                            style: AppTextStyles.extraLarge.copyWith(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            AppStrings.addLinksDescription.tr,
                            style: AppTextStyles.extraLarge.copyWith(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 15),
                          // Icon rows
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Image.asset(MyImages.insta,
                                  width: 50, height: 50),
                              Image.asset(MyImages.tiktok,
                                  width: 50, height: 50),
                              Image.asset(MyImages.snapchat,
                                  width: 50, height: 50),
                              Image.asset(MyImages.linkedId,
                                  width: 50, height: 50),
                              Image.asset(MyImages.xmaster,
                                  width: 50, height: 50),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Image.asset(MyImages.spotify,
                                  width: 50, height: 50),
                              Image.asset(MyImages.facebook,
                                  width: 50, height: 50),
                              Image.asset(MyImages.strava,
                                  width: 50, height: 50),
                              Image.asset(MyImages.youtube,
                                  width: 50, height: 50),
                              Image.asset(MyImages.discord,
                                  width: 50, height: 50),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            AppStrings.supportedLinks.tr,
                            style: AppTextStyles.extraLarge.copyWith(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 15),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Existing links display
                    if (controller.links.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.link,
                                    color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Your Existing Links',
                                  style: AppTextStyles.extraLarge.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'These links are already saved to your profile:',
                              style: AppTextStyles.extraLarge.copyWith(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Editable rows for new links
                    ...List.generate(
                      (_linkCount - controller.links.length)
                          .clamp(0, _linkCount),
                      (i) {
                        final index = controller.links.length + i;
                        final linkType = _linkTypes[index];
                        final linkName = linkType == 'custom'
                            ? 'Website'
                            : _supportedLinks[linkType]!['name'];
                        final linkIcon = linkType == 'custom'
                            ? MyImages.website
                            : _supportedLinks[linkType]!['icon'];

                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: GestureDetector(
                                    onTap: () {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      _showLinkSelector(context, index);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Row(
                                          children: [
                                            Image.asset(linkIcon,
                                                width: 38,
                                                height: 38), // <-- updated
                                            const Icon(Icons.arrow_drop_down,
                                                size: 19),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 7,
                                  child: myFieldAdvance(
                                    focusNode: _linkFocusNodes[index],
                                    context: context,
                                    controller: _linkControllers[index],
                                    hintText:
                                        'Enter $linkName ${linkName == "Phone" ? "Number" : linkName == "Email" ? "Id" : "URL"}',
                                    inputType: TextInputType.text,
                                    textInputAction: TextInputAction.done,
                                    fillColor: Colors.transparent,
                                    textBack: Colors.transparent,
                                  ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.delete,
                                      size: 20, color: Colors.grey),
                                  onPressed: () {
                                    setState(() {
                                      if (_linkCount >
                                          controller.links.length) {
                                        _linkControllers.removeAt(index);
                                        _linkFocusNodes.removeAt(index);
                                        _linkTypes.removeAt(index);
                                        _linkCount--;
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: CustomButton(
                        buttonColor: MyColors.textBlack,
                        textColor: MyColors.textWhite,
                        text: AppStrings.addAnotherLink.tr,
                        onPressed: () {
                          setState(() {
                            _linkControllers.add(TextEditingController());
                            _linkFocusNodes.add(FocusNode());
                            _linkTypes.add('instagram');
                            _linkCount++;
                          });
                        },
                      ),
                    ),

                    // Bottom submit button
                    if (_linkCount > controller.links.length)
                      Obx(
                        () => controller.isLoading.value
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.black))
                            : Padding(
                                padding: const EdgeInsets.only(
                                    left: 60.0, right: 60.0, top: 10),
                                child: CustomButton(
                                  buttonColor: MyColors.textBlack,
                                  textColor: MyColors.textWhite,
                                  text: "Go to your hub",
                                  onPressed: () async {
                                    bool hasEmpty = false;
                                    bool hasDuplicate = false;

                                    for (int i = controller.links.length;
                                        i < _linkCount;
                                        i++) {
                                      final url =
                                          _linkControllers[i].text.trim();
                                      if (url.isNotEmpty) {
                                        final existingLink = controller.links
                                            .any((link) =>
                                                link.url.toLowerCase() ==
                                                    url.toLowerCase() ||
                                                link.url.toLowerCase().contains(
                                                    url.toLowerCase()) ||
                                                url.toLowerCase().contains(
                                                    link.url.toLowerCase()));

                                        if (existingLink) {
                                          hasDuplicate = true;
                                          SnackbarUtil.showError(
                                              "Link '${_linkTypes[i]}' with URL '$url' already exists in your profile.");
                                          break;
                                        }
                                      }
                                    }

                                    if (hasDuplicate) return;

                                    for (int i = _linkCount - 1;
                                        i >= controller.links.length;
                                        i--) {
                                      final url =
                                          _linkControllers[i].text.trim();
                                      if (url.isEmpty) {
                                        _linkControllers.removeAt(i);
                                        _linkTypes.removeAt(i);
                                        _linkCount--;
                                        hasEmpty = true;
                                      } else {
                                        await controller.createLink(
                                          name: _linkTypes[i],
                                          type: _linkTypes[i],
                                          url: url,
                                          call: () {
                                            Get.offAll(() => BottomNavScreen());
                                          },
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLinkSelector(BuildContext context, int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black26, // semi-transparent background
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;

        return Align(
          alignment: Alignment.centerLeft, // left-center
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(5),
              width: screenWidth * 0.35, // smaller width
              height: screenHeight * 0.51, // half screen height
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 0,
                      mainAxisSpacing: 0,
                      childAspectRatio: 1.2,
                      children: _supportedLinks.entries.map((entry) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _linkTypes[index] = entry.key;
                            });
                          },
                          child: SizedBox(
                            width: 30, // slightly smaller than before
                            height: 30, // slightly smaller than before
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(6.0), // medium padding
                              child: Image.asset(
                                entry.value['icon'],
                                width: 26, // medium icon size
                                height: 26,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _linkTypes[index] = 'custom';
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.language, color: Colors.white, size: 30),
                          SizedBox(width: 6),
                          Text(
                            "Custom",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: "Outfit",
                                fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
