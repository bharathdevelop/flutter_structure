import 'package:flutter/material.dart';
import 'package:flutter_structure/core/common_widget/common_drawer.dart';
import 'package:flutter_structure/core/constant/colors.dart';

class DrawerDash extends StatelessWidget {
  const DrawerDash({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: secondary,
      child: SafeArea(
        child:Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(context, '/profilepage');
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: secondary,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person_rounded),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "orgName",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "myUserName",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // DrawerItem(icon: "icon", title: "title", onTap: (){}),
            // DrawerItem(icon: "icon", title: "title", onTap: (){}),
            // DrawerItem(icon: "icon", title: "title", onTap: (){}),
            // DrawerItem(icon: "icon", title: "title", onTap: (){}),
          ],
        ) 
      ),
    );
  }
}