import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,

        title: const Text(
          'Offers & Coupons',

          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),

        iconTheme:
            const IconThemeData(
          color: Colors.black,
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('coupons')
            .where(
              'isActive',
              isEqualTo: true,
            )
            .snapshots(),

        builder: (context, snapshot) {

          // LOADING
          if (snapshot.connectionState ==
              ConnectionState.waiting) {

            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          // EMPTY
          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {

            return _EmptyOffers();
          }

          final offers =
              snapshot.data!.docs;

          return ListView.builder(
            padding:
                const EdgeInsets.all(16),

            itemCount: offers.length,

            itemBuilder: (_, index) {

              final data =
                  offers[index].data()
                      as Map<String, dynamic>;

              final couponCode =
                  data['code'] ?? '';

              final description =
                  data['description'] ?? '';

              final type =
                  data['type'] ?? '';

              final value =
                  data['value'] ?? 0;

              final minOrder =
                  data['minOrderAmount'] ?? 0;

              String offerText = '';

              // FLAT COUPON
              if (type.toString().toLowerCase() ==
                  'flat') {

                offerText =
                    '₹$value OFF • Min Order ₹$minOrder';
              }

              // PERCENTAGE COUPON
              else {

                offerText =
                    '$value% OFF • Min Order ₹$minOrder';
              }

              return Container(
                margin:
                    const EdgeInsets.only(
                  bottom: 16,
                ),

                padding:
                    const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color:
                      const Color(0xFFFFF3E0),

                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),

                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    // ICON
                    Container(
                      width: 54,
                      height: 54,

                      decoration:
                          BoxDecoration(
                        color: Colors.white,

                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),

                      child: const Icon(
                        Icons
                            .local_offer_rounded,

                        color:
                            AppColors
                                .electricCoral,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [

                          // DESCRIPTION
                          Text(
                            description,

                            style:
                                const TextStyle(
                              fontSize: 18,

                              fontWeight:
                                  FontWeight
                                      .w700,

                              color: Colors.black,
                            ),
                          ),

                          const SizedBox(
                              height: 6),

                          // DETAILS
                          Text(
                            offerText,

                            style: TextStyle(
                              color:
                                  Colors
                                      .grey
                                      .shade700,

                              fontSize: 14,

                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),

                          const SizedBox(
                              height: 14),

                          // COUPON BOX
                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),

                            decoration:
                                BoxDecoration(
                              color: Colors.white,

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),

                            child: Row(
                              children: [

                                Expanded(
                                  child: Text(
                                    couponCode,

                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .w700,

                                      letterSpacing:
                                          1,

                                      fontSize: 16,
                                    ),
                                  ),
                                ),

                                GestureDetector(
                                  onTap:
                                      () async {

                                    await Clipboard
                                        .setData(
                                      ClipboardData(
                                        text:
                                            couponCode,
                                      ),
                                    );

                                    ScaffoldMessenger.of(
                                            context)
                                        .showSnackBar(
                                      SnackBar(
                                        content:
                                            Text(
                                          '$couponCode copied',
                                        ),

                                        behavior:
                                            SnackBarBehavior
                                                .floating,
                                      ),
                                    );
                                  },

                                  child:
                                      Container(
                                    padding:
                                        const EdgeInsets
                                            .all(
                                      8,
                                    ),

                                    decoration:
                                        BoxDecoration(
                                      color: AppColors
                                          .electricCoral
                                          .withOpacity(
                                              0.1),

                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        8,
                                      ),
                                    ),

                                    child:
                                        const Icon(
                                      Icons
                                          .copy_rounded,

                                      size: 18,

                                      color: AppColors
                                          .electricCoral,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

// EMPTY STATE
class _EmptyOffers extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 32,
        ),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            Container(
              width: 100,
              height: 100,

              decoration: BoxDecoration(
                color: AppColors
                    .electricCoral
                    .withOpacity(0.08),

                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.local_offer_rounded,

                size: 46,

                color:
                    AppColors.electricCoral,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'No Offers Available',

              style: TextStyle(
                fontSize: 22,

                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'New coupons and exciting deals will appear here soon.',

              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 14,

                color:
                    Colors.grey.shade600,

                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}