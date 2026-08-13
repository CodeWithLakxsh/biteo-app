import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() =>
      _SupportScreenState();
}

class _SupportScreenState
    extends State<SupportScreen> {

  final TextEditingController _controller =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  // 🔥 YOUR LIVE AI URL
  final String supportApi =
    'YOUR_LIVE_AI_URL';

  String? ticketId;

  bool isSending = false;

  @override
  void initState() {
    super.initState();
    _createTicket();
  }

  // =========================================================
  // CREATE SUPPORT TICKET
  // =========================================================

  Future<void> _createTicket() async {

    final user =
        FirebaseAuth.instance.currentUser;

    final doc = await FirebaseFirestore.instance
        .collection('support_tickets')
        .add({
      'ticket_id':
          DateTime.now()
              .millisecondsSinceEpoch
              .toString(),

      'user_id': user?.uid,

      'user_name':
          user?.displayName ?? 'Customer',

      'user_phone':
          user?.phoneNumber ?? '',

      'status': 'ai',

      'representative_joined': false,

      'created_at':
          FieldValue.serverTimestamp(),

      'updated_at':
          FieldValue.serverTimestamp(),
    });

    setState(() {
      ticketId = doc.id;
    });
  }

  // =========================================================
  // SEND MESSAGE
  // =========================================================

  Future<void> _sendMessage() async {

    if (_controller.text.trim().isEmpty ||
        ticketId == null ||
        isSending) {
      return;
    }

    final user =
        FirebaseAuth.instance.currentUser;

    final text =
        _controller.text.trim();

    _controller.clear();

    setState(() {
      isSending = true;
    });

    // =====================================================
    // SAVE USER MESSAGE
    // =====================================================

    await FirebaseFirestore.instance
        .collection('support_tickets')
        .doc(ticketId)
        .collection('messages')
        .add({
      'sender': 'user',
      'message': text,
      'created_at':
          FieldValue.serverTimestamp(),
    });

    _scrollBottom();

    try {

      // ===================================================
      // CALL AI API
      // ===================================================

      final response = await http.post(
        Uri.parse(supportApi),

        headers: {
          'Content-Type': 'application/json',
        },

        body: jsonEncode({
          'message': text,
          'userId': user?.uid,
        }),
      );

      final data =
          jsonDecode(response.body);

      final aiReply =
          data['reply'] ??
              'Support unavailable right now.';

      // ===================================================
      // SAVE AI MESSAGE
      // ===================================================

      await FirebaseFirestore.instance
          .collection('support_tickets')
          .doc(ticketId)
          .collection('messages')
          .add({
        'sender': 'ai',
        'message': aiReply,
        'created_at':
            FieldValue.serverTimestamp(),
      });

      // ===================================================
      // UPDATE AI SUMMARY
      // ===================================================

      await FirebaseFirestore.instance
          .collection('support_tickets')
          .doc(ticketId)
          .update({
        'last_message': text,
        'updated_at':
            FieldValue.serverTimestamp(),
      });

    } catch (e) {

      // ===================================================
      // FALLBACK MESSAGE
      // ===================================================

      await FirebaseFirestore.instance
          .collection('support_tickets')
          .doc(ticketId)
          .collection('messages')
          .add({
        'sender': 'ai',
        'message':
            'Support is temporarily unavailable. Please try again shortly.',
        'created_at':
            FieldValue.serverTimestamp(),
      });
    }

    setState(() {
      isSending = false;
    });

    _scrollBottom();
  }

  // =========================================================
  // representative TRANSFER
  // =========================================================

  Future<void> _transferToRepresentative() async {

    if (ticketId == null) return;

    await FirebaseFirestore.instance
        .collection('support_tickets')
        .doc(ticketId)
        .update({
      'status': 'representative_waiting',

      'representative_requested': true,

      'updated_at':
          FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('support_tickets')
        .doc(ticketId)
        .collection('messages')
        .add({
      'sender': 'system',
      'message':
          'A Biteo support representative will join shortly.',

      'created_at':
          FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Support representative requested.'
          ),
        ),
      );
    }
  }

  // =========================================================
  // AUTO SCROLL
  // =========================================================

  void _scrollBottom() {

    Future.delayed(
      const Duration(milliseconds: 300),
      () {

        if (_scrollController.hasClients) {

          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,

            duration:
                const Duration(milliseconds: 300),

            curve: Curves.easeOut,
          );
        }
      },
    );
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,

        title: const Text(
          'Biteo Support',
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

      body: Column(
        children: [

          // =================================================
          // CHAT
          // =================================================

          Expanded(
            child: ticketId == null
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : StreamBuilder<QuerySnapshot>(

                    stream: FirebaseFirestore
                        .instance
                        .collection(
                            'support_tickets')
                        .doc(ticketId)
                        .collection('messages')
                        .orderBy('created_at')
                        .snapshots(),

                    builder:
                        (context, snapshot) {

                      if (!snapshot.hasData) {
                        return const SizedBox();
                      }

                      final docs =
                          snapshot.data!.docs;

                      return ListView.builder(

                        controller:
                            _scrollController,

                        padding:
                            const EdgeInsets.all(
                                16),

                        itemCount: docs.length,

                        itemBuilder:
                            (_, index) {

                          final data =
                              docs[index].data()
                                  as Map<String,
                                      dynamic>;

                          final sender =
                              data['sender'];

                          final isUser =
                              sender == 'user';

                          final isSystem =
                              sender == 'system';

                          return Align(

                            alignment: isUser
                                ? Alignment
                                    .centerRight
                                : Alignment
                                    .centerLeft,

                            child: Container(

                              constraints:
                                  BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(
                                                context)
                                            .size
                                            .width *
                                        0.75,
                              ),

                              margin:
                                  const EdgeInsets.only(
                                      bottom: 12),

                              padding:
                                  const EdgeInsets.all(
                                      14),

                              decoration:
                                  BoxDecoration(

                                color: isSystem
                                    ? Colors.black
                                        .withOpacity(
                                            0.05)

                                    : isUser
                                        ? const Color(
                                            0xFFFFE0B2)

                                        : Colors.grey
                                            .shade200,

                                borderRadius:
                                    BorderRadius
                                        .circular(
                                            16),
                              ),

                              child: Text(

                                data['message'] ??
                                    '',

                                style: TextStyle(
                                  fontSize: 15,

                                  color: isSystem
                                      ? Colors.black54
                                      : Colors.black,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),

          // =================================================
          // representative BUTTON
          // =================================================

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
            ),

            child: Align(
              alignment:
                  Alignment.centerLeft,

              child: TextButton.icon(

                onPressed:
                    _transferToRepresentative,

                icon: const Icon(
                  Icons.support_agent_rounded,
                ),

                label: const Text(
                  'Talk to Representative',
                ),
              ),
            ),
          ),

          // =================================================
          // INPUT
          // =================================================

          SafeArea(
            top: false,

            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                      16, 0, 16, 16),

              child: Row(
                children: [

                  Expanded(
                    child: TextField(

                      controller:
                          _controller,

                      minLines: 1,
                      maxLines: 4,

                      decoration:
                          InputDecoration(

                        hintText:
                            'Describe your issue...',

                        filled: true,

                        fillColor:
                            Colors.grey.shade100,

                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),

                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  16),
                          borderSide:
                              BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  GestureDetector(

                    onTap:
                        isSending
                            ? null
                            : _sendMessage,

                    child: Container(

                      width: 52,
                      height: 52,

                      decoration:
                          const BoxDecoration(
                        color:
                            Color(0xFFFF6B35),
                        shape: BoxShape.circle,
                      ),

                      child: isSending

                          ? const Padding(
                              padding:
                                  EdgeInsets.all(
                                      14),
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )

                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}