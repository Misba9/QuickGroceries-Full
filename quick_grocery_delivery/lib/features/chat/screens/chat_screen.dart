import 'package:flutter/material.dart';
import 'package:quick_grocery_delivery/constants/app_icons.dart';
import 'package:quick_grocery_delivery/constants/global_variables.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              const Center(
                child: Text(
                  'Chats',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GlobalVariables.verticalSpace,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                width: width,
                height: height * .07,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: GlobalVariables.lightGrey,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      height: 25,
                      width: 25,
                      child: Image.asset(AppIcons.search),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search your customerss',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(child: Center(child: Text('No chats Found!'))),
              // GlobalVariables.verticalSpace,
              // ListView.builder(
              //     shrinkWrap: true,
              //     itemCount: 4,
              //     itemBuilder: (context, i) {
              //       return ChatTile(width: width, height: height);
              //     })
            ],
          ),
        ),
      ),
    );
  }
}

class ChatTile extends StatelessWidget {
  const ChatTile({Key? key, required this.width, required this.height})
    : super(key: key);

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: width,
      height: height * .11,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const SizedBox(height: 50, width: 50, child: CircleAvatar()),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Sangeeth',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'whare is  your loca...',
                    style: TextStyle(
                      color: GlobalVariables.darkGrey,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
                child: const Center(
                  child: Text(
                    '1',
                    style: TextStyle(color: GlobalVariables.secondary),
                  ),
                ),
              ),
              const Text(
                '10:38',
                style: TextStyle(color: GlobalVariables.darkGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
