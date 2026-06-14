// lib/services/paystack_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class Plan {
  final String id;
  final String name;
  final String price;
  final int amountKobo;
  final List<String> features;
  final bool isPopular;

  const Plan({
    required this.id,
    required this.name,
    required this.price,
    required this.amountKobo,
    required this.features,
    this.isPopular = false,
  });
}

class PaystackService {
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  static const List<Plan> plans = [
    Plan(
      id: 'starter',
      name: 'STARTER',
      price: 'Free',
      amountKobo: 0,
      features: [
        '50 AI questions/month',
        '1 subject',
        'Basic quiz modes',
        '500MB storage',
      ],
    ),
    Plan(
      id: 'pro',
      name: 'PRO',
      price: '₦1,500/mo',
      amountKobo: 150000,
      features: [
        'Unlimited questions',
        '5 subjects',
        'All test modes',
        '5GB storage',
        'AI Tutor chat',
        'Weakness tracking',
      ],
      isPopular: true,
    ),
    Plan(
      id: 'elite',
      name: 'ELITE',
      price: '₦3,500/mo',
      amountKobo: 350000,
      features: [
        'Everything in Pro',
        'Unlimited subjects',
        'Offline mode',
        'Group study rooms',
        'Priority support',
      ],
    ),
  ];

  Future<void> initialize() async {
    // Paystack mobile SDK — initialized on mobile only
  }

  Future<bool> subscribe(BuildContext context, Plan plan) async {
    // TODO: integrate flutter_paystack on mobile build
    // For now show a coming soon dialog
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F1117),
        title: const Text('Coming Soon',
            style: TextStyle(color: Color(0xFFE8ECF7))),
        content: Text('Payment for ${plan.name} plan will be available soon.',
            style: const TextStyle(color: Color(0xFFB8BFD4))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF3B82F6))),
          ),
        ],
      ),
    );
    return false;
  }

  Future<void> _grantAccess(String uid, String planId, String reference) async {
    final expiry = DateTime.now().add(const Duration(days: 30));
    await _db.collection('users').doc(uid).update({
      'plan': planId,
      'subscriptionExpiry': Timestamp.fromDate(expiry),
      'lastPaymentReference': reference,
    });
  }

  Future<String> getUserPlan(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return 'starter';
    final data = doc.data()!;
    final plan = data['plan'] as String? ?? 'starter';
    final expiry = (data['subscriptionExpiry'] as Timestamp?)?.toDate();
    if (expiry != null && expiry.isBefore(DateTime.now())) return 'starter';
    return plan;
  }
}