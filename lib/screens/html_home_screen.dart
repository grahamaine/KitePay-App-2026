import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'dart:developer' as dev; // Use this instead of print

class HtmlHomeScreen extends StatelessWidget {
  const HtmlHomeScreen({super.key});

  static const String _htmlData = '''
    <div style="background-color: #f8fafc; font-family: sans-serif; padding: 20px;">
      <div style="background: linear-gradient(135deg, #2563eb 0%, #7c3aed 100%); 
                  padding: 24px; border-radius: 20px; color: white;">
        <div style="font-size: 13px; opacity: 0.9;">Current Balance</div>
        <div style="font-size: 36px; font-weight: 700; margin: 8px 0;">\$14,280.50</div>
      </div>

      <h3 style="margin-top: 30px;">Quick Actions</h3>
      <div style="display: flex; gap: 15px;">
        <a href="kitepay://send" style="text-decoration: none; flex: 1;">
          <div style="background: white; padding: 20px; border-radius: 16px; text-align: center; border: 1px solid #e2e8f0;">
            <span>📤</span><br><b style="color: #1e293b;">Send</b>
          </div>
        </a>
        <a href="kitepay://receive" style="text-decoration: none; flex: 1;">
          <div style="background: white; padding: 20px; border-radius: 16px; text-align: center; border: 1px solid #e2e8f0;">
            <span>📥</span><br><b style="color: #1e293b;">Receive</b>
          </div>
        </a>
      </div>
    </div>
  ''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: HtmlWidget(
          _htmlData,
          onTapUrl: (url) {
            if (url == 'kitepay://send') {
              dev.log("Navigating to Send Screen");
            } else if (url == 'kitepay://receive') {
              dev.log("Navigating to Receive Screen");
            }
            return true;
          },
          // Note: If RenderMode still shows as undefined, 
          // it might be because the package version changed. 
          // You can safely remove it to use the default layout.
        ),
      ),
    );
  }
}
