import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/setting_controller/SettingController.dart';
import '../../model/FaqListModel.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  _FAQScreenState createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final SettingController _settingController = Get.put(SettingController());

  @override
  void initState() {
    super.initState();
    _settingController.fetchFaq();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'FAQs',
          style: TextStyle(
            fontFamily: "Outfit",

            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Obx(() {
        if (_settingController.faqLoader.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        } else if (_settingController.faq.isEmpty) {
          return const Center(
            child: Text(
              'No FAQs available',
              style: TextStyle(color: Colors.white, fontSize: 16,            fontFamily: "Outfit",
              ),
            ),
          );
        } else {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _settingController.faq.length,
            itemBuilder: (context, index) {
              Faq item = _settingController.faq[index];
              return FAQItem(
                question: item.question ?? '',
                answer: item.answer ?? '',
                isLast: index == _settingController.faq.length - 1,
              );
            },
          );
        }
      }),
    );
  }
}

class FAQItem extends StatefulWidget {
  final String question;
  final String answer;
  final bool isLast;

  const FAQItem({
    super.key,
    required this.question,
    required this.answer,
    this.isLast = false,
  });

  @override
  _FAQItemState createState() => _FAQItemState();
}

class _FAQItemState extends State<FAQItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: widget.isLast ? 0 : 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          widget.question,
          style: const TextStyle(
            fontFamily: "Outfit",

            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        trailing: Icon(
          _isExpanded ? Icons.remove : Icons.add,
          color: Colors.white,
        ),
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        children: [
          Text(
            widget.answer,
            style: const TextStyle(
              fontFamily: "Outfit",

              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}