import 'package:flutter/material.dart';

enum SortType {
  recommended,
  priceLow,
  priceHigh,
  ratingHigh,
  newest,
}

class ListingFilter {
  // ORTAK
  final String? categoryId;
  final int? minPrice;
  final int? maxPrice;
  final double? minRating;
  final SortType sort;

  // CAMP
  final DateTimeRange? dateRange;
  final int? guests;

  // CARAVAN
  final int? minYear;
  final int? maxYear;

  // PRODUCT
  final bool? onlyNew; // null=hepsi, true=sıfır, false=2.el

  const ListingFilter({
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.sort = SortType.recommended,
    this.dateRange,
    this.guests,
    this.minYear,
    this.maxYear,
    this.onlyNew,
  });

  ListingFilter copyWith({
    String? categoryId,
    int? minPrice,
    int? maxPrice,
    double? minRating,
    SortType? sort,
    DateTimeRange? dateRange,
    int? guests,
    int? minYear,
    int? maxYear,
    bool? onlyNew,
  }) {
    return ListingFilter(
      categoryId: categoryId ?? this.categoryId,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      sort: sort ?? this.sort,
      dateRange: dateRange ?? this.dateRange,
      guests: guests ?? this.guests,
      minYear: minYear ?? this.minYear,
      maxYear: maxYear ?? this.maxYear,
      onlyNew: onlyNew ?? this.onlyNew,
    );
  }
}
