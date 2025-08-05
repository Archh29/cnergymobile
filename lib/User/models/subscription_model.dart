import 'package:flutter/material.dart';

class SubscriptionPlan {
  final int id;
  final String planName;
  final double price;
  final double? discountedPrice;
  final bool isMemberOnly;
  final List<Feature> features;

  SubscriptionPlan({
    required this.id,
    required this.planName,
    required this.price,
    this.discountedPrice,
    required this.isMemberOnly,
    required this.features,
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
      features: (json['features'] as List<dynamic>?)
              ?.map((featureJson) => Feature.fromJson(featureJson))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_name': planName,
      'price': price,
      'discounted_price': discountedPrice,
      'is_member_only': isMemberOnly,
      'features': features.map((feature) => feature.toJson()).toList(),
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
      return '${date.day}/${date.month}/${date.year}';
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
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
