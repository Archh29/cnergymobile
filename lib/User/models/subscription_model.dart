import 'package:flutter/material.dart';

class SubscriptionPlan {
  final int id;
  final String planName;
  final double price;
  final double? discountedPrice;
  final bool isMemberOnly;
  final int durationMonths;
  final bool isAvailable;
  final String? unavailableReason;
  final String? description;
  final List<Feature> features;
  
  // New lock-related fields
  final bool isLocked;
  final String? lockReason;
  final String? lockMessage;
  final String? lockIcon;

  SubscriptionPlan({
    required this.id,
    required this.planName,
    required this.price,
    this.discountedPrice,
    required this.isMemberOnly,
    this.durationMonths = 1,
    this.isAvailable = true,
    this.unavailableReason,
    this.description,
    required this.features,
    this.isLocked = false,
    this.lockReason,
    this.lockMessage,
    this.lockIcon,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: int.parse(json['id'].toString()),
      planName: json['plan_name']?.toString() ?? 'Unnamed Plan',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      discountedPrice: json['discounted_price'] != null
          ? double.tryParse(json['discounted_price'].toString())
          : null,
      isMemberOnly: json['is_member_only'] == 1 || json['is_member_only'] == true,
      durationMonths: int.tryParse(json['duration_months']?.toString() ?? '1') ?? 1,
      isAvailable: json['is_available'] == true,
      unavailableReason: json['unavailable_reason']?.toString(),
      description: json['description']?.toString(),
      features: (json['features'] as List<dynamic>?)
              ?.map((featureJson) => Feature.fromJson(featureJson))
              .toList() ??
          [],
      // New lock-related fields
      isLocked: json['is_locked'] == true,
      lockReason: json['lock_reason']?.toString(),
      lockMessage: json['lock_message']?.toString(),
      lockIcon: json['lock_icon']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_name': planName,
      'price': price,
      'discounted_price': discountedPrice,
      'is_member_only': isMemberOnly,
      'duration_months': durationMonths,
      'is_available': isAvailable,
      'unavailable_reason': unavailableReason,
      'description': description,
      'features': features.map((feature) => feature.toJson()).toList(),
      'is_locked': isLocked,
      'lock_reason': lockReason,
      'lock_message': lockMessage,
      'lock_icon': lockIcon,
    };
  }

  String getFormattedPrice() => '₱${price.toStringAsFixed(2)}';

  String? getFormattedDiscountedPrice() {
    return discountedPrice != null ? '₱${discountedPrice!.toStringAsFixed(2)}' : null;
  }

  bool get hasDiscount => discountedPrice != null && discountedPrice! < price;

  double get effectivePrice => discountedPrice ?? price;

  String getFormattedEffectivePrice() => '₱${effectivePrice.toStringAsFixed(2)}';

  double? get discountPercentage {
    if (!hasDiscount) return null;
    return ((price - discountedPrice!) / price) * 100;
  }

  String? getFormattedDiscountPercentage() {
    final percentage = discountPercentage;
    return percentage != null ? '${percentage.toStringAsFixed(0)}% OFF' : null;
  }

  String getDurationText() {
    if (planName.toLowerCase().contains('member fee')) {
      return '1 Year';
    } else if (planName.toLowerCase().contains('day pass')) {
      return '1 Day';
    }
    return durationMonths == 1 ? '1 Month' : durationMonths == 0 ? '1 Day' : '$durationMonths Months';
  }

  String getPlanTypeText() {
    if (planName.toLowerCase().contains('member fee')) {
      return 'Annual Membership';
    } else if (isMemberOnly) {
      return 'Member Monthly Plan';
    } else {
      return 'Non-Member Monthly Plan';
    }
  }

  bool get isMembershipPlan => planName.toLowerCase().contains('member fee');
  bool get isMonthlyPlan => !isMembershipPlan;

  String getAvailabilityText() {
    if (isAvailable) {
      return 'Available';
    } else {
      return unavailableReason ?? 'Not Available';
    }
  }

  String getDisplayName() {
    if (planName.toLowerCase().contains('gym membership fee')) {
      return 'Gym Membership';
    } else if (planName.toLowerCase().contains('non-member')) {
      return planName.replaceAll('Non-Member', 'Standard');
    }
    return planName;
  }
}

class Feature {
  final String featureName;
  final String description;

  Feature({
    required this.featureName,
    required this.description,
  });

  factory Feature.fromJson(Map<String, dynamic> json) {
    return Feature(
      featureName: json['feature_name']?.toString() ?? 'Unnamed Feature',
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feature_name': featureName,
      'description': description,
    };
  }
}

class UserSubscription {
  final int id;
  final String planName;
  final double price;
  final double? discountedPrice;
  final String statusName;
  final String startDate;
  final String endDate;
  final String? createdAt;

  UserSubscription({
    required this.id,
    required this.planName,
    required this.price,
    this.discountedPrice,
    required this.statusName,
    required this.startDate,
    required this.endDate,
    this.createdAt,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: int.parse(json['id'].toString()),
      planName: json['plan_name']?.toString() ?? 'Unnamed Plan',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      discountedPrice: json['discounted_price'] != null
          ? double.tryParse(json['discounted_price'].toString())
          : null,
      statusName: json['status_name']?.toString() ?? 'Unknown',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_name': planName,
      'price': price,
      'discounted_price': discountedPrice,
      'status_name': statusName,
      'start_date': startDate,
      'end_date': endDate,
      'created_at': createdAt,
    };
  }

  String getFormattedPrice() => '₱${price.toStringAsFixed(2)}';

  String? getFormattedDiscountedPrice() =>
      discountedPrice != null ? '₱${discountedPrice!.toStringAsFixed(2)}' : null;

  bool get hasDiscount => discountedPrice != null && discountedPrice! < price;

  double get effectivePrice => discountedPrice ?? price;

  String getFormattedEffectivePrice() => '₱${effectivePrice.toStringAsFixed(2)}';

  Color getStatusColor() {
    switch (statusName.toLowerCase()) {
      case 'pending_approval':
        return Colors.orange;
      case 'approved':
      case 'active':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'expired':
        return Colors.grey;
      case 'cancelled':
        return Colors.red.shade300;
      default:
        return Colors.blue;
    }
  }

  String getStatusDisplayName() {
    switch (statusName.toLowerCase()) {
      case 'pending_approval':
        return 'Pending Approval';
      case 'approved':
        return 'Approved';
      case 'active':
        return 'Active';
      case 'declined':
        return 'Declined';
      case 'expired':
        return 'Expired';
      case 'cancelled':
        return 'Cancelled';
      default:
        return statusName;
    }
  }

  String getFormattedDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String getFormattedStartDate() => getFormattedDate(startDate);
  String getFormattedEndDate() => getFormattedDate(endDate);

  String? getFormattedCreatedAt() {
    if (createdAt == null) return null;
    try {
      final date = DateTime.parse(createdAt!);
      final hour = date.hour;
      final minute = date.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year} $displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return createdAt;
    }
  }
}

// Response models
class SubscriptionRequestResponse {
  final bool success;
  final String message;
  final SubscriptionRequestData? data;

  SubscriptionRequestResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory SubscriptionRequestResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionRequestResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null
          ? SubscriptionRequestData.fromJson(json['data'])
          : null,
    );
  }
}

class SubscriptionRequestData {
  final int subscriptionId;
  final String userName;
  final String planName;
  final double price;
  final double? discountedPrice;
  final String status;
  final String startDate;
  final String endDate;

  SubscriptionRequestData({
    required this.subscriptionId,
    required this.userName,
    required this.planName,
    required this.price,
    this.discountedPrice,
    required this.status,
    required this.startDate,
    required this.endDate,
  });

  factory SubscriptionRequestData.fromJson(Map<String, dynamic> json) {
    return SubscriptionRequestData(
      subscriptionId: int.parse(json['subscription_id'].toString()),
      userName: json['user_name']?.toString() ?? 'Unknown User',
      planName: json['plan_name']?.toString() ?? 'Unknown Plan',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      discountedPrice: json['discounted_price'] != null
          ? double.tryParse(json['discounted_price'].toString())
          : null,
      status: json['status']?.toString() ?? 'Unknown',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
    );
  }
}

class UserSubscriptionStatus {
  final bool isPremium;
  final bool hasActiveMembership;
  final List<Map<String, dynamic>> activeSubscriptions;

  UserSubscriptionStatus({
    required this.isPremium,
    required this.hasActiveMembership,
    required this.activeSubscriptions,
  });

  factory UserSubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionStatus(
      isPremium: json['is_premium'] == true,
      hasActiveMembership: json['has_active_membership'] == true,
      activeSubscriptions: (json['active_subscriptions'] as List<dynamic>?)
              ?.map((sub) => Map<String, dynamic>.from(sub))
              .toList() ??
          [],
    );
  }
}

class SubscriptionPlansResponse {
  final bool success;
  final List<SubscriptionPlan> plans;
  final UserSubscriptionStatus userStatus;
  final String message;

  SubscriptionPlansResponse({
    required this.success,
    required this.plans,
    required this.userStatus,
    required this.message,
  });
}

class SubscriptionEligibility {
  final bool isEligible;
  final String? reason;
  final SubscriptionPlan? plan;
  final UserSubscriptionStatus? userStatus;

  SubscriptionEligibility({
    required this.isEligible,
    this.reason,
    this.plan,
    this.userStatus,
  });
}
