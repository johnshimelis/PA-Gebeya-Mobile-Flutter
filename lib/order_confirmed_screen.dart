import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:laza/components/bottom_nav_button.dart';
import 'package:laza/components/custom_appbar.dart';
import 'package:laza/extensions/context_extension.dart';
import 'orders_screen.dart'; // Import your order screen
import 'home_screen.dart'; // Import your home screen
import 'dashboard.dart'; // Import your home screen

class OrderConfirmedScreen extends StatelessWidget {
  const OrderConfirmedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.theme.appBarTheme.systemOverlayStyle!,
      child: Scaffold(
        appBar: const CustomAppBar(),
        bottomNavigationBar: BottomNavButton(
          label: 'Continue Shopping',
          onTap: () {
            // Navigate to HomeScreen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        ),
        body: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset('assets/images/mask_group.png'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(
                    flex: 3,
                  ),
                  Center(
                      child: SvgPicture.asset(
                          'assets/images/order_confirmed.svg')),
                  const SizedBox(height: 40.0),
                  Column(
                    children: [
                      Text(
                        'Order Confirmed!',
                        style: context.headlineMedium,
                      ),
                      const SizedBox(height: 10.0),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 25.0),
                        child: Text(
                          'Your order has been confirmed, we will send you confirmation email shortly.',
                          style:
                              TextStyle(fontSize: 15, color: Color(0xff8F959E)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: InkWell(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(10.0)),
                      onTap: () {
                        // Navigate to OrderScreen with the required callback
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrdersScreen(
                              onOrderUpdated: () {
                                // Define what should happen when the order is updated
                                // For example, you might want to refresh the order list or show a snackbar
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Order updated!'),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                      child: Ink(
                        width: double.infinity,
                        height: 50,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(10.0)),
                          color: Color(0xffF5F5F5),
                        ),
                        child: const Center(
                          child: Text(
                            'Go to Orders',
                            style: TextStyle(
                                fontSize: 17.0,
                                color: Color(0xff8F959E),
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
