import 'package:flutter/material.dart';

import '../constants/colors.dart';
import 'custom_toast.dart';

class NoInternetPage extends StatelessWidget {
  const NoInternetPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          automaticallyImplyLeading: false,
          title: const Text('No internet'),
          centerTitle: true,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.signal_wifi_connected_no_internet_4,
                color: primaryColor,
                size: 80,
              ),
              const SizedBox(height: 16),
              const Column(
                children: [
                  Text(
                    'No Internet Connection',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Check your connection',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: 100,
                child: ElevatedButton(
                  onPressed: () {
                    CustomToast.showToast('No Internet, try again');
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(primaryColor),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
        ),
      );
}
