import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

class CouponSelectionScreen extends StatelessWidget {

  final int cartTotalPaise;

  const CouponSelectionScreen({
    super.key,
    required this.cartTotalPaise,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Coupons'),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('coupons')
            .where('isActive', isEqualTo: true)
            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {

            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('No coupons available'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,

            itemBuilder: (context, index) {

              final coupon =
                  docs[index].data()
                      as Map<String, dynamic>;

              return Container(
                margin: const EdgeInsets.only(
                  bottom: 14,
                ),

                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(16),

                  border: Border.all(
                    color: AppColors.grey200,
                  ),
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(
                      coupon['code'] ?? '',
                      style: AppTextStyles
                          .headlineSmall
                          .copyWith(
                        color:
                            AppColors.electricCoral,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      coupon['description'] ?? '',
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Min order ₹${coupon['minOrderAmount'] ?? 0}',
                      style: AppTextStyles.caption,
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,

                      child: ElevatedButton(
                        onPressed: () {

                          final minOrder =
                              coupon['minOrderAmount'] ?? 0;

                          if ((cartTotalPaise / 100)
                              < minOrder) {

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Minimum order ₹$minOrder required',
                                ),
                              ),
                            );

                            return;
                          }

                          final type =
                              coupon['type'] ?? 'flat';

                          final value =
                              coupon['value'] ?? 0;

                          final maxDiscount =
                              (coupon['maxDiscount'] ?? 999999)
                                  .toDouble();

                          int discountPaise = 0;

                          if (type == 'percentage') {

                            double calculated =
                                ((cartTotalPaise / 100) * value) / 100;

                            if (calculated > maxDiscount) {
                              calculated = maxDiscount;
                            }

                            discountPaise =
                                (calculated * 100).round();

                          } else {

                            discountPaise =
                                (value * 100).toInt();
                          }

                          context.pop({
                            'couponCode': coupon['code'],
                            'discountPaise': discountPaise,
                            'couponData': coupon,
                          });
                        },

                        child: const Text(
                          'Apply Coupon',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}