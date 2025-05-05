import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

enum LanguageEvent { toEnglish, toChineseSimplified, toChineseTraditional }

class LanguageState {
  final Locale locale;
  
  LanguageState(this.locale);
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LanguageState &&
           other.locale.languageCode == locale.languageCode &&
           other.locale.countryCode == locale.countryCode;
  }
  
  @override
  int get hashCode => locale.hashCode;
}

class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  static const String LANGUAGE_CODE = 'languageCode';
  static const String COUNTRY_CODE = 'countryCode';
  
  final SharedPreferences sharedPreferences;

  LanguageBloc({required this.sharedPreferences}) : super(LanguageState(const Locale('zh', 'TW'))) {
    on<LanguageEvent>(_onLanguageEvent);
    _initLanguage();
  }

  void _initLanguage() {
    final languageCode = sharedPreferences.getString(LANGUAGE_CODE) ?? 'zh';
    final countryCode = sharedPreferences.getString(COUNTRY_CODE) ?? 'TW';
    
    if (languageCode == 'zh') {
      if (countryCode == 'CN') {
        add(LanguageEvent.toChineseSimplified);
      } else if (countryCode == 'TW') {
        add(LanguageEvent.toChineseTraditional);
      }
    } else if (languageCode == 'en') {
      add(LanguageEvent.toEnglish);
    }
  }

  Future<void> _onLanguageEvent(LanguageEvent event, Emitter<LanguageState> emit) async {
    switch (event) {
      case LanguageEvent.toEnglish:
        await sharedPreferences.setString(LANGUAGE_CODE, 'en');
        await sharedPreferences.setString(COUNTRY_CODE, '');
        emit(LanguageState(const Locale('en')));
        break;
      case LanguageEvent.toChineseSimplified:
        await sharedPreferences.setString(LANGUAGE_CODE, 'zh');
        await sharedPreferences.setString(COUNTRY_CODE, 'CN');
        emit(LanguageState(const Locale('zh', 'CN')));
        break;
      case LanguageEvent.toChineseTraditional:
        await sharedPreferences.setString(LANGUAGE_CODE, 'zh');
        await sharedPreferences.setString(COUNTRY_CODE, 'TW');
        emit(LanguageState(const Locale('zh', 'TW')));
        break;
    }
  }
}