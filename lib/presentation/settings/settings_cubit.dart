import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suefery/core/utils/logger.dart';
import 'package:suefery/data/service/service_pref.dart';
import 'package:suefery/locator.dart';

import '../../data/repository/i_repo_firestore.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final Locale locale;

  const SettingsState({
    required this.themeMode,
    required this.locale,
  });

  factory SettingsState.initial() {
    return const SettingsState(
      themeMode: ThemeMode.light,
      locale: Locale('en'),
    );
  }

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }

  @override
  List<Object> get props => [themeMode, locale];
}


class SettingsCubit extends Cubit<SettingsState> with LogMixin{
  final ServicePref _prefService = sl<ServicePref>();
  final _firestoreRepo = sl<IRepoFirestore>();

  SettingsCubit() : super(SettingsState.initial());

  /// Loads the user's saved settings from preferences.
  void loadSettings() {
    logInfo('Loading user settings...');
    final isDark = _prefService.isDarkTheme;
    final langCode = _prefService.language;

    emit(state.copyWith(
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(langCode),
    ));
  }

  /// Sets a new locale and persists it.
  void setLocale(Locale newLocale) {
    if (state.locale == newLocale) return;

    _prefService.setlanguage(newLocale.languageCode);
    emit(state.copyWith(locale: newLocale));
  }

  /// Toggles dark mode and persists the choice.
  void toggleDarkMode(bool isDark) {
    final newMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _prefService.setThemeDark(isDark);
    emit(state.copyWith(themeMode: newMode));
  }

  Future<void> seedBrands() async {
    logInfo('Starting brand seeding...');
    // The complete list of Egyptian market brands
    final brands = [
      // --- Dairy ---
      {"name": "Juhayna", "category": "Dairy", "priority": 100},
      {"name": "Lamar", "category": "Dairy", "priority": 95},
      {"name": "Almarai", "category": "Dairy", "priority": 95},
      {"name": "Beyty", "category": "Dairy", "priority": 90},
      {"name": "Domty", "category": "Dairy", "priority": 85},
      {"name": "Obour Land", "category": "Dairy", "priority": 85},
      {"name": "Panda", "category": "Dairy", "priority": 80},
      {"name": "Kiri", "category": "Dairy", "priority": 75},
      {"name": "Katilo", "category": "Dairy", "priority": 70},
      
      // --- Beverages ---
      {"name": "Coca-Cola", "category": "Beverages", "priority": 100},
      {"name": "Pepsi", "category": "Beverages", "priority": 100},
      {"name": "7Up", "category": "Beverages", "priority": 90},
      {"name": "Fayrouz", "category": "Beverages", "priority": 85},
      {"name": "Spiro Spathis", "category": "Beverages", "priority": 95},
      {"name": "Baraka", "category": "Water", "priority": 90},
      {"name": "Hayat", "category": "Water", "priority": 90},
      {"name": "Dasani", "category": "Water", "priority": 90},

      // --- Snacks ---
      {"name": "Chipsy", "category": "Snacks", "priority": 100},
      {"name": "Tiger", "category": "Snacks", "priority": 95},
      {"name": "Rotato", "category": "Snacks", "priority": 85},
      {"name": "Doritos", "category": "Snacks", "priority": 95},
      {"name": "Molto", "category": "Bakery", "priority": 100},
      {"name": "Todo", "category": "Bakery", "priority": 95},
      {"name": "Hohos", "category": "Bakery", "priority": 90},
      {"name": "Bimbo", "category": "Biscuits", "priority": 85},
      {"name": "Corona", "category": "Chocolate", "priority": 85},
      {"name": "Cadbury", "category": "Chocolate", "priority": 100},
      {"name": "Galaxy", "category": "Chocolate", "priority": 95},

      // --- Pantry ---
      {"name": "El Doha", "category": "Pantry", "priority": 100},
      {"name": "Reggina", "category": "Pasta", "priority": 95},
      {"name": "Italiano", "category": "Pasta", "priority": 95},
      {"name": "Harvest", "category": "Canned", "priority": 90},
      {"name": "Vitrac", "category": "Jam", "priority": 90},
      {"name": "Isis", "category": "Herbs", "priority": 90},
      {"name": "El Arosa", "category": "Tea", "priority": 100},
      {"name": "Lipton", "category": "Tea", "priority": 100},
      {"name": "Crystal", "category": "Oil", "priority": 95},
      {"name": "Fern", "category": "Ghee", "priority": 90},

      // --- Frozen ---
      {"name": "Basma", "category": "Frozen", "priority": 95},
      {"name": "Farm Frites", "category": "Frozen", "priority": 95},
      {"name": "Atyab", "category": "Frozen Meat", "priority": 95},
      {"name": "Halwani Bros", "category": "Frozen Meat", "priority": 95},
      {"name": "Koki", "category": "Frozen Meat", "priority": 90},

      // --- Cleaning & Care ---
      {"name": "Ariel", "category": "Cleaning", "priority": 100},
      {"name": "Persil", "category": "Cleaning", "priority": 100},
      {"name": "Oxi", "category": "Cleaning", "priority": 95},
      {"name": "Pril", "category": "Dishwashing", "priority": 95},
      {"name": "Fairy", "category": "Dishwashing", "priority": 95},
      {"name": "Dettol", "category": "Disinfectant", "priority": 100},
      {"name": "Pampers", "category": "Baby", "priority": 100},
      {"name": "Molfix", "category": "Baby", "priority": 95},
      {"name": "Nivea", "category": "Skin", "priority": 100},
      {"name": "Dove", "category": "Skin", "priority": 95},
      {"name": "Signal", "category": "Oral", "priority": 95},
      {"name": "Pantene", "category": "Hair", "priority": 95},
    ];

    // Prepare the data for the generic batchSet method.
    // Each map needs an 'id' key.
    final List<Map<String, dynamic>> brandsWithIds = brands.map((brand) {
      final docId =
          brand['name'].toString().toLowerCase().replaceAll(' ', '_');
      return {
        'id': docId, // The ID for the document
        'name': brand['name'],
        'category': brand['category'],
        'priority': brand['priority'],
        'searchKey': brand['name'].toString().toLowerCase(),
      };
    }).toList();

    // Use the repository to perform the batch write.
    await _firestoreRepo.batchSet('brands',brandsWithIds);
    logInfo('Brand seeding completed via repository.');
  }
}