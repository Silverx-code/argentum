// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionPlan { free, pro, elite }

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? university;
  final bool emailVerified;
  final SubscriptionPlan plan;
  final DateTime? subscriptionExpiry;
  final int streakDays;
  final int totalQuestions;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.university,
    required this.emailVerified,
    this.plan = SubscriptionPlan.free,
    this.subscriptionExpiry,
    this.streakDays = 0,
    this.totalQuestions = 0,
    required this.createdAt,
    this.lastLoginAt,
  });

  // ── Factory: from Firestore document ────────────────────────────────
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid:                data['uid']          as String,
      email:              data['email']        as String,
      displayName:        data['displayName']  as String,
      photoUrl:           data['photoUrl']     as String?,
      university:         data['university']   as String?,
      emailVerified:      data['emailVerified'] as bool? ?? false,
      plan:               _planFromString(data['plan'] as String? ?? 'free'),
      subscriptionExpiry: (data['subscriptionExpiry'] as Timestamp?)?.toDate(),
      streakDays:         data['streakDays']      as int? ?? 0,
      totalQuestions:     data['totalQuestions']  as int? ?? 0,
      createdAt:          (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt:        (data['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  // ── To Firestore map ─────────────────────────────────────────────────
  Map<String, dynamic> toFirestore() => {
    'uid':                uid,
    'email':              email,
    'displayName':        displayName,
    'photoUrl':           photoUrl,
    'university':         university,
    'emailVerified':      emailVerified,
    'plan':               plan.name,
    'subscriptionExpiry': subscriptionExpiry != null
        ? Timestamp.fromDate(subscriptionExpiry!)
        : null,
    'streakDays':         streakDays,
    'totalQuestions':     totalQuestions,
    'createdAt':          Timestamp.fromDate(createdAt),
    'lastLoginAt':        lastLoginAt != null
        ? Timestamp.fromDate(lastLoginAt!)
        : null,
  };

  // ── copyWith ─────────────────────────────────────────────────────────
  UserModel copyWith({
    String?           displayName,
    String?           photoUrl,
    String?           university,
    bool?             emailVerified,
    SubscriptionPlan? plan,
    DateTime?         subscriptionExpiry,
    int?              streakDays,
    int?              totalQuestions,
    DateTime?         lastLoginAt,
  }) {
    return UserModel(
      uid:                uid,
      email:              email,
      displayName:        displayName        ?? this.displayName,
      photoUrl:           photoUrl           ?? this.photoUrl,
      university:         university         ?? this.university,
      emailVerified:      emailVerified      ?? this.emailVerified,
      plan:               plan               ?? this.plan,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      streakDays:         streakDays         ?? this.streakDays,
      totalQuestions:     totalQuestions     ?? this.totalQuestions,
      createdAt:          createdAt,
      lastLoginAt:        lastLoginAt        ?? this.lastLoginAt,
    );
  }

  bool get isPro   => plan == SubscriptionPlan.pro   || plan == SubscriptionPlan.elite;
  bool get isElite => plan == SubscriptionPlan.elite;

  static SubscriptionPlan _planFromString(String s) {
    switch (s) {
      case 'pro':   return SubscriptionPlan.pro;
      case 'elite': return SubscriptionPlan.elite;
      default:      return SubscriptionPlan.free;
    }
  }
}
