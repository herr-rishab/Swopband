// import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:swopband/controller/user_controller/UserController.dart';

// import 'package:swopband/view/network/ApiService.dart';
import 'package:swopband/view/utils/app_constants.dart';
import 'package:swopband/view/utils/shared_pref/SharedPrefHelper.dart';
import 'package:swopband/view/widgets/custom_button.dart';
import 'package:swopband/view/widgets/custom_textfield.dart';
import 'package:swopband/view/widgets/custom_snackbar.dart';
import '../../controller/link_controller/LinkController.dart';
import '../utils/images/iamges.dart';
import '../utils/app_text_styles.dart';
import '../utils/app_colors.dart';
import '../translations/app_strings.dart';

class EditLinksScreen extends StatefulWidget {
  const EditLinksScreen({super.key});

  @override
  State<EditLinksScreen> createState() => _EditLinksScreenState();
}

class _EditLinksScreenState extends State<EditLinksScreen> {
  final List<TextEditingController> _linkControllers = [];
  final List<String> _linkTypes = [];
  int _linkCount = 0;
  final controller = Get.put(LinkController());
  final userController = Get.put(UserController());

  late Worker _linksWorker;
  String imageUrl = "";

  // —— UI constants (kept minimal; only UI adjustments) ——
  static const double kSide = 20; // page horizontal padding (your original)
  static const double kHeaderRadius = 22;
  static const double kRowHeight = 45;
  static const double kRowRadius = 30;
  static const double kRowBorder = 1.5;
  static const double kLeftIcon = 44; // icon box size
  static const double kGap = 12;
  static const double kFieldLeftPadding = 17;

  // Method to launch URLs
  Future<void> _launchUrl(String url) async {
    try {
      String finalUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        finalUrl = 'https://$url';
      }
      final Uri uri = Uri.parse(finalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        SnackbarUtil.showError('Could not launch $finalUrl');
      }
    } catch (e) {
      SnackbarUtil.showError('Error launching URL: $e');
    }
  }

  final Map<String, String> _platformImages = {
    'instagram': MyImages.insta,
    'snapchat': MyImages.tiktok,
    'linkedin': MyImages.snapchat,
    'x': MyImages.linkedId,
    'spotify': MyImages.xmaster,
    'facebook': MyImages.spotify,
    'strava': MyImages.facebook,
    'youtube': MyImages.strava,
    'tiktok': MyImages.youtube,
    'discord': MyImages.discord,
  };

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
    // 'custom': {'name': 'Website', 'icon': MyImages.website},
    'phone': {'name': 'Phone', 'icon': MyImages.phone},
    'email': {'name': 'Email', 'icon': MyImages.email},
  };

  final Map<String, Map<String, dynamic>> _supportedLinksReadOnly = {
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
    'custom': {'name': 'Website', 'icon': MyImages.website},
    'phone': {'name': 'Phone', 'icon': MyImages.phone},
    'email': {'name': 'Email', 'icon': MyImages.email},
  };

  @override
  void initState() {
    super.initState();
    _checkAuth();
    // Register 'ever' immediately
    _linksWorker = ever(controller.links, (_) {
      if (!mounted) return;

      _linkControllers.clear();
      _linkTypes.clear();

      for (var link in controller.links) {
        _linkControllers.add(TextEditingController(text: link.url));
        _linkTypes.add(link.type);
      }

      // Clean up any invalid link types for new additions
      for (int i = 0; i < _linkTypes.length; i++) {
        if (i >= controller.links.length) {
          if (!_supportedLinksReadOnly.containsKey(_linkTypes[i])) {
            _linkTypes[i] = 'instagram';
          }
        }
      }

      if (_linkControllers.isEmpty) {
        _linkControllers.add(TextEditingController());
        _linkTypes.add('instagram');
      }

      setState(() {
        _linkCount = _linkControllers.length;
      });
    });

    // Fetch after setting up 'ever'
    controller.fetchLinks();
  }

  Future<void> _checkAuth() async {
    final firebaseId = await SharedPrefService.getString('firebase_id');
    log("firebaseId  : $firebaseId");

    if (firebaseId != null && firebaseId.isNotEmpty) {
      await userController.fetchUserByFirebaseId(firebaseId);
      imageUrl = sanitizeProfileUrl(AppConst.USER_PROFILE as String?);
    }
  }

  String sanitizeProfileUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (kIsWeb && url.startsWith('http://profile.swopband.com')) {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  @override
  void dispose() {
    _linksWorker.dispose();
    for (var controller in _linkControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showEditDialog(int index) {
    final link = controller.links[index];
    final TextEditingController urlController =
    TextEditingController(text: link.url);

    // use the same list _linkTypes
    String selectedType = _linkTypes[index];

    if (!_supportedLinks.containsKey(selectedType) &&
        selectedType != 'custom') {
      selectedType = 'instagram'; // fallback
      _linkTypes[index] = selectedType;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final linkName = selectedType == 'custom'
                ? 'Website'
                : _supportedLinks[selectedType]!['name'];
            final linkIcon = selectedType == 'custom'
                ? MyImages.website
                : _supportedLinks[selectedType]!['icon'];

            return AlertDialog(
              backgroundColor: MyColors.backgroundColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              title: const Text(
                'Edit Link',
                style: TextStyle(
                  fontFamily: "Outfit",
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _showLinkSelectorEdit(context, index, (newType) {
                            setStateDialog(() {
                              selectedType = newType; // local update
                              _linkTypes[index] = newType; // list update
                            });
                          });
                        },
                        child: Row(
                          children: [
                            Image.asset(linkIcon, width: 40, height: 40),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: urlController,
                          decoration: InputDecoration(
                            labelStyle: const TextStyle(
                              fontFamily: "Outfit",
                            ),
                            labelText:
                            'Enter $linkName ${linkName == "Phone" ? "Number" : linkName == "Email" ? "Id" : "URL"}',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          keyboardType: TextInputType.text,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: "Outfit",
                    ),
                  ),
                ),
                Obx(() => controller.isLoading.value
                    ? const CircularProgressIndicator()
                    : TextButton(
                  onPressed: () async {
                    await controller.updateLink(
                      id: link.id,
                      type: _linkTypes[index],
                      url: urlController.text.trim(),
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: "Outfit",
                    ),
                  ),
                )),
              ],
            );
          },
        );
      },
    );
  }

  /// update showLinkSelector to accept callback
  void _showLinkSelectorEdit(
      BuildContext context, int index, Function(String)? onSelected) {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;

        return Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(5),
              width: screenWidth * 0.35,
              height: screenHeight * 0.45,
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
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      childAspectRatio: 1.2,
                      children: _supportedLinks.entries.map((entry) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _linkTypes[index] = entry.key;
                            });
                            if (onSelected != null) onSelected(entry.key);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Image.asset(
                              entry.value['icon'],
                              width: 28,
                              height: 28,
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _linkTypes[index] = 'custom';
                      });
                      if (onSelected != null) onSelected('custom');
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
                              fontSize: 15,
                            ),
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

  Widget _buildPlatformImage(String platform, bool isActive) {
    // Styled cell like the mock (rounded + thin white stroke)
    return Container(
      width: 54.4,
      height: 54.4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.white, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        _platformImages[platform] ?? MyImages.insta,
        fit: BoxFit.cover,
      ),
    );
  }

  // —— READONLY LINK ROW (no black circle behind icon) ——
  Widget _readonlyLinkRow({
    required String type,
    required String url,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final icon = _supportedLinksReadOnly[type]?['icon'] ?? MyImages.insta;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // just the brand icon (no background)
        SizedBox(
          width: kLeftIcon,
          height: kLeftIcon,
          child: Image.asset(icon, fit: BoxFit.contain),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.arrow_drop_down, size: 18, color: Colors.black),
        const SizedBox(width: kGap),
        // pill field with underline text + 3-dots menu
        Expanded(
          child: Container(
            height: kRowHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kRowRadius),
              border: Border.all(color: Colors.black, width: kRowBorder),
            ),
            padding: const EdgeInsets.only(left: kFieldLeftPadding, right: 6),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _launchUrl(url),
                    child: Text(
                      url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: "Outfit",
                        fontSize: 16,
                        color: Colors.black,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  color: Colors.white,
                  icon: const Icon(Icons.more_vert,
                      color: Colors.black, size: 20, weight: 10),
                  onSelected: (String value) async {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (BuildContext context) => const [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.black, size: 17),
                          SizedBox(width: 8),
                          Text('Edit',
                              style: TextStyle(fontFamily: "Outfit")),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.black),
                          SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(fontFamily: "Outfit")),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      body: SafeArea(
        child: Obx(
              () => controller.fetchLinkLoader.value
              ? const Center(child: CircularProgressIndicator())
              : Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: kSide),
                child: DefaultTextStyle(
                  style: const TextStyle(fontFamily: 'Outfit'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),

                      // —— Header black card (same as mock) ——
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius:
                          BorderRadius.circular(kHeaderRadius),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 6),
                            const Text(
                              'Add links',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 34,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Add up to 10 links here, including your\nphone number and email.\nYou can also add a custom web link.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16,
                                color: Colors.white,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                _buildPlatformImage(
                                    'instagram',
                                    controller.links.any((link) =>
                                    link.type == 'instagram')),
                                _buildPlatformImage(
                                    'snapchat',
                                    controller.links.any((link) =>
                                    link.type == 'snapchat')),
                                _buildPlatformImage(
                                    'linkedin',
                                    controller.links.any((link) =>
                                    link.type == 'linkedin')),
                                _buildPlatformImage(
                                    'x',
                                    controller.links
                                        .any((link) => link.type == 'x')),
                                _buildPlatformImage(
                                    'spotify',
                                    controller.links.any((link) =>
                                    link.type == 'spotify')),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                _buildPlatformImage(
                                    'facebook',
                                    controller.links.any((link) =>
                                    link.type == 'facebook')),
                                _buildPlatformImage(
                                    'strava',
                                    controller.links.any((link) =>
                                    link.type == 'strava')),
                                _buildPlatformImage(
                                    'youtube',
                                    controller.links.any((link) =>
                                    link.type == 'youtube')),
                                _buildPlatformImage(
                                    'tiktok',
                                    controller.links.any((link) =>
                                    link.type == 'tiktok')),
                                _buildPlatformImage(
                                    'discord',
                                    controller.links.any((link) =>
                                    link.type == 'discord')),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Supported links. More coming soon!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 26),

                      // —— Readonly API links (restyled; no black circle) ——
                      ...List.generate(
                        controller.links.length,
                            (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: _readonlyLinkRow(
                            type: controller.links[index].type,
                            url: controller.links[index].url,
                            onEdit: () => _showEditDialog(index),
                            onDelete: () async {
                              final link = controller.links[index];
                              await controller.deleteLink(
                                  link.id, link.type);
                            },
                          ),
                        ),
                      ),

                      // —— Editable fields for new links (no black circle) ——
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
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.center,
                              children: [
                                // left brand icon (no background) + ▼
                                GestureDetector(
                                  onTap: () =>
                                      _showLinkSelector(context, index),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: kLeftIcon,
                                        height: kLeftIcon,
                                        child: Image.asset(
                                          linkIcon,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.arrow_drop_down,
                                          size: 18, color: Colors.black),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: kGap),
                                // pill text field
                                Expanded(
                                  child: Container(
                                    height: kRowHeight,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                      BorderRadius.circular(
                                          kRowRadius),
                                      border: Border.all(
                                        color: Colors.black,
                                        width: kRowBorder,
                                      ),
                                    ),
                                    padding: const EdgeInsets.only(
                                        left: kFieldLeftPadding,
                                        right: 6),
                                    child: Center(
                                      child: myFieldAdvance(
                                        context: context,
                                        controller:
                                        _linkControllers[index],
                                        hintText:
                                        'Enter $linkName ${linkName == "Phone" ? "Number" : linkName == "Email" ? "Id" : "URL"}',
                                        inputType: TextInputType.text,
                                        textInputAction: index <
                                            _linkControllers.length -
                                                1
                                            ? TextInputAction.next
                                            : TextInputAction.done,
                                        fillColor: Colors.transparent,
                                        textBack: Colors.transparent,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      size: 20, color: Colors.grey),
                                  onPressed: () {
                                    setState(() {
                                      if (_linkCount >
                                          controller.links.length) {
                                        _linkControllers.removeAt(index);
                                        _linkTypes.removeAt(index);
                                        _linkCount--;
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // + Add another link (black pill)
                      CustomButton(
                        buttonColor: MyColors.textBlack,
                        textColor: MyColors.textWhite,
                        text: AppStrings.addAnotherLink.tr,
                        onPressed: () {
                          setState(() {
                            _linkControllers
                                .add(TextEditingController());
                            _linkTypes.add('instagram');
                            _linkCount++;
                          });
                        },
                      ),

                      if (_linkCount > controller.links.length)
                        Obx(
                              () => controller.isLoading.value
                              ? const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: CircularProgressIndicator(
                                color: Colors.black,
                              ),
                            ),
                          )
                              : Padding(
                            padding: const EdgeInsets.only(
                                left: 60.0, right: 60.0, top: 10),
                            child: CustomButton(
                              buttonColor: MyColors.textBlack,
                              textColor: MyColors.textWhite,
                              text: AppStrings.apply.tr,
                              onPressed: () async {
                                // Loop backwards to safely remove empty links while iterating
                                for (int i = _linkCount - 1;
                                i >= controller.links.length;
                                i--) {
                                  final url =
                                  _linkControllers[i]
                                      .text
                                      .trim();

                                  if (url.isEmpty) {
                                    _linkControllers.removeAt(i);
                                    _linkTypes.removeAt(i);
                                    _linkCount--;
                                  } else {
                                    await controller.createLink(
                                      name: _linkTypes[i],
                                      type: _linkTypes[i],
                                      url: url,
                                      call: () {},
                                    );
                                  }
                                }
                                controller.fetchLinks();
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: 80)
                    ],
                  ),
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
      barrierColor: Colors.black26,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;

        return Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(5),
              width: screenWidth * 0.35,
              height: screenHeight * 0.51,
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
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      childAspectRatio: 1.2,
                      children: _supportedLinks.entries.map((entry) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _linkTypes[index] = entry.key;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Image.asset(
                              entry.value['icon'],
                              width: 28,
                              height: 28,
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _linkTypes[index] = 'custom';
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.language, color: Colors.white, size: 27),
                            SizedBox(width: 6),
                            Text(
                              "Custom",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: "Outfit",
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
