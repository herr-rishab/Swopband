import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:developer';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../utils/images/iamges.dart';
import '../../controller/recent_swoppers_controller/RecentSwoppersController.dart';
import '../../model/RecentSwoppersModel.dart';
import 'swopband_webview_screen.dart';

class RecentSwoppersScreen extends StatefulWidget {
  const RecentSwoppersScreen({super.key});

  @override
  State<RecentSwoppersScreen> createState() => _RecentSwoppersScreenState();
}

class _RecentSwoppersScreenState extends State<RecentSwoppersScreen> {
  final RecentSwoppersController controller =
  Get.put(RecentSwoppersController());
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });

    // Update UI when list changes
    ever(controller.recentSwoppers, (List<User> swoppers) {
      if (!mounted) return;
      setState(() {});
      log("🔄 RecentSwoppersScreen: Updated filtered list with ${swoppers.length} connections");
    });
  }

  @override
  Widget build(BuildContext context) {
    // Spacing constants
    const double kSidePaddingHeader = 28; // header as per Figma
    const double kSidePaddingBody = 22;   // reduced but not too much
    const double kCountFontSize = 150;
    const double kTitleFontSize = 34;
    const double kSearchHeight = 41;
    const double kSearchRadius = 30;
    const double kSearchBorder = 1.5;
    const double kSearchHintFont = 16;
    const double kBetweenSearchAndList = 23;

    // Row item constants
    const double kListItemHeight = 57;
    const double kListItemRadius = 28.5;
    const double kAvatarSize = 47;
    const double kArrowCircle = 47;
    const double kArrowSize = 20; // bigger right-arrow

    return Scaffold(
      backgroundColor: MyColors.backgroundColor,
      body: SafeArea(
        child: DefaultTextStyle(
          style: const TextStyle(fontFamily: 'Outfit'),
          child: Column(
            children: [
              // a little space above the big number
              const SizedBox(height: 24),

              // HEADER (keeps original 28px horizontal padding)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kSidePaddingHeader),
                child: Column(
                  children: [
                    // Big Count (centered)
                    Text(
                      controller.connectionCount.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: kCountFontSize,
                        height: 1.0,
                        fontWeight: FontWeight.w700,
                        color: MyColors.textBlack,
                        letterSpacing: -2,
                      ),
                    ),

                    // Pull "Connections" closer to number
                    Transform.translate(
                      offset: const Offset(0, -8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min, // keeps refresh close
                        children: [
                          const Text(
                            "Connections",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: kTitleFontSize,
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                              color: MyColors.textBlack,
                            ),
                          ),
                          const SizedBox(width: 8), // EXACT 8px gap
                          GestureDetector(
                            onTap: () => controller.fetchRecentSwoppers(),
                            child: CircleAvatar(
                              radius: 15, // old style
                              backgroundColor: Colors.grey.shade300,
                              child: const Icon(
                                Icons.refresh,
                                color: Colors.blue,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // SEARCH (body padding 22)
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kSidePaddingBody),
                child: SizedBox(
                  height: kSearchHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(kSearchRadius),
                      border: Border.all(color: Colors.black, width: kSearchBorder),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: kSearchHintFont,
                        color: Colors.black,
                        height: 1.25,
                      ),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search Connections',
                        hintStyle: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: kSearchHintFont,
                          color: Colors.black.withOpacity(0.36),
                          height: 1.25,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 17,
                          vertical: 10,
                        ),
                        // taller/bigger search icon
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: kSearchHeight,
                        ),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(3.1415926535),
                            child: const Icon(
                              Icons.search,
                              size: 28,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: kBetweenSearchAndList),

              // LIST (body padding 22)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: kSidePaddingBody),
                  child: Obx(() {
                    final String q = _searchController.text.trim().toLowerCase();
                    final List<User> visible = q.isEmpty
                        ? controller.recentSwoppers
                        : controller.recentSwoppers
                        .where((u) =>
                    (u.name).toLowerCase().contains(q) ||
                        (u.username).toLowerCase().contains(q))
                        .toList();

                    if (controller.fetchRecentSwoppersLoader.value) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            CircularProgressIndicator(color: MyColors.textBlack),
                            SizedBox(height: 16),
                            Text(
                              'Loading connections...',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16,
                                color: MyColors.textBlack,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (controller.recentSwoppers.isEmpty) {
                      return Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.nfc, size: 64, color: MyColors.textDisabledColor),
                              SizedBox(height: 16),
                              Text(
                                'No NFC connections yet',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16,
                                  color: MyColors.textDisabledColor,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'When someone touches their NFC ring to your device,\n they will appear here automatically',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14,
                                  color: MyColors.textDisabledColor,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: Colors.black,
                      onRefresh: () => controller.fetchRecentSwoppers(),
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 12),
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final user = visible[index];
                          return _ConnectionTile(
                            user: user,
                            onTap: () {
                              Get.to(() => SwopbandWebViewScreen(
                                username: user.username,
                                url: '',
                              ));
                            },
                            onLongPress: () => _showUserOptions(user),
                            itemHeight: kListItemHeight,
                            itemRadius: kListItemRadius,
                            avatarSize: kAvatarSize,
                            arrowCircle: kArrowCircle,
                            arrowSize: kArrowSize,
                          );
                        },
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickConnectDialog() {
    _usernameController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Connect', style: TextStyle(fontFamily: "Outfit")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter username to connect instantly:',
                style: TextStyle(fontFamily: "Outfit")),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                hintStyle: TextStyle(fontFamily: "Outfit"),
                hintText: 'e.g., ranga013',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              autofocus: true,
              onSubmitted: (value) async {
                if (value.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  await _connectWithUsername(value.trim());
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(fontFamily: "Outfit")),
          ),
          ElevatedButton(
            onPressed: () async {
              final username = _usernameController.text.trim();
              if (username.isNotEmpty) {
                Navigator.of(context).pop();
                await _connectWithUsername(username);
              }
            },
            child: const Text('Connect', style: TextStyle(fontFamily: "Outfit")),
          ),
        ],
      ),
    );
  }

  Future<void> _connectWithUsername(String username) async {
    try {
      Get.dialog(
        const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Creating connection...', style: TextStyle(fontFamily: "Outfit")),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      final success = await controller.createConnection(username);
      Get.back();

      if (success) {
        Get.snackbar(
          'Success',
          'Connected with @$username',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Failed',
          'Could not connect with @$username',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Error',
        'Failed to connect: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showUserOptions(User user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.white),
              title: Text(
                'View Profile',
                style: AppTextStyles.medium.copyWith(
                  fontFamily: 'Outfit',
                  color: Colors.white,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => SwopbandWebViewScreen(username: user.username, url: ''));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                'Remove Connection',
                style: AppTextStyles.medium.copyWith(
                  fontFamily: 'Outfit',
                  color: Colors.red,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showRemoveConfirmation(user);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showRemoveConfirmation(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Connection', style: TextStyle(fontFamily: "Outfit")),
        content: Text(
          'Are you sure you want to remove @${user.username} from your connections?',
          style: const TextStyle(fontFamily: "Outfit"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(fontFamily: "Outfit")),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (user.connectionId != null) {
                controller.removeConnection(user.connectionId!);
                Get.snackbar(
                  'Removed',
                  'Connection with @${user.username} removed',
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                );
              } else {
                Get.snackbar(
                  'Error',
                  'Connection ID not found',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.white, fontFamily: "Outfit"),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionTile extends StatelessWidget {
  final User user;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  final double itemHeight;
  final double itemRadius;
  final double avatarSize;
  final double arrowCircle;
  final double arrowSize;

  const _ConnectionTile({
    required this.user,
    required this.onTap,
    required this.onLongPress,
    required this.itemHeight,
    required this.itemRadius,
    required this.avatarSize,
    required this.arrowCircle,
    required this.arrowSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: itemHeight,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(itemRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            // Avatar
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              clipBehavior: Clip.antiAlias,
              child: (user.profileUrl != null && user.profileUrl!.isNotEmpty)
                  ? Image.network(user.profileUrl!, fit: BoxFit.cover)
                  : Image.asset(MyImages.profileImage, fit: BoxFit.cover),
            ),
            const SizedBox(width: 16),

            // Name + username
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),

            // Right-arrow in white 47px circle (bigger icon)
            Container(
              width: arrowCircle,
              height: arrowCircle,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_forward, // solid right arrow
                size: arrowSize,      // 20px now
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
