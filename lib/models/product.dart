import 'package:flutter/material.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.icon,
    required this.rating,
    required this.stock,
    required this.description,
  });

  final int id;
  final String name;
  final String brand;
  final String category;
  final double price;
  final IconData icon;
  final double rating;
  final String stock;
  final String description;
}

class ShippingAddress {
  const ShippingAddress({
    required this.label,
    required this.recipient,
    required this.phone,
    required this.address,
    this.isDefault = false,
  });

  final String label;
  final String recipient;
  final String phone;
  final String address;
  final bool isDefault;

  ShippingAddress copyWith({
    String? label,
    String? recipient,
    String? phone,
    String? address,
    bool? isDefault,
  }) {
    return ShippingAddress(
      label: label ?? this.label,
      recipient: recipient ?? this.recipient,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class PaymentMethodItem {
  const PaymentMethodItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isDefault = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDefault;

  PaymentMethodItem copyWith({
    String? title,
    String? subtitle,
    IconData? icon,
    bool? isDefault,
  }) {
    return PaymentMethodItem(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
