// ignore_for_file: constant_identifier_names

import 'package:get/get.dart';
import 'package:greenfestival/admin.dart';
import 'package:greenfestival/mobile.dart';
import 'package:greenfestival/ui/views/age_view.dart';
import 'package:greenfestival/ui/views/display_live_view.dart';
import 'package:greenfestival/ui/views/ending_view.dart';
import 'package:greenfestival/ui/views/gender_view.dart';
import 'package:greenfestival/ui/views/home_view.dart';
import 'package:greenfestival/ui/views/intro_view.dart';
import 'package:greenfestival/ui/views/nickname_view.dart';
import 'package:greenfestival/ui/views/participant_count_view.dart';
import 'package:greenfestival/ui/views/phone_number_view.dart';
import 'package:greenfestival/ui/views/privacy_consent_view.dart';
import 'package:greenfestival/ui/views/ready_view.dart';
import 'package:greenfestival/ui/views/residence_view.dart';
import 'package:greenfestival/ui/views/survey_view.dart';

class AppPages {
  static const INITIAL = '/';
  static const HOME = '/home';
  static const INTRO = '/intro';
  static const PRIVACY_CONSENT = '/privacy-consent';
  static const NICKNAME = '/nickname';
  static const GENDER = '/gender';
  static const AGE = '/age';
  static const PARTICIPANT_COUNT = '/participant-count';
  static const RESIDENCE = '/residence';
  static const PHONE_NUMBER = '/phone-number';
  static const READY = '/ready';
  static const ENDING = '/ending';
  static const SURVEY = '/survey';
  static const ADMIN = '/admin';
  static const DISPLAY_LIVE = '/display/live';
  static const STAMP_TOUR = '/stamp-tour';

  static final pages = [
    GetPage(name: INITIAL, page: () => const IntroView()),
    GetPage(name: HOME, page: () => const HomeView()),
    GetPage(name: INTRO, page: () => const IntroView()),
    GetPage(name: PRIVACY_CONSENT, page: () => const PrivacyConsentView()),
    GetPage(name: NICKNAME, page: () => const NicknameView()),
    GetPage(name: GENDER, page: () => const GenderView()),
    GetPage(name: AGE, page: () => const AgeView()),
    GetPage(name: PARTICIPANT_COUNT, page: () => const ParticipantCountView()),
    GetPage(name: RESIDENCE, page: () => const ResidenceView()),
    GetPage(name: PHONE_NUMBER, page: () => const PhoneNumberView()),
    GetPage(name: READY, page: () => const ReadyView()),
    GetPage(name: ENDING, page: () => const EndingView()),
    GetPage(name: SURVEY, page: () => SurveyView()),
    GetPage(name: ADMIN, page: () => const AdminPage()),
    GetPage(name: DISPLAY_LIVE, page: () => const DisplayLiveView()),
    GetPage(
      name: '$STAMP_TOUR/:uid',
      page: () => SeedStampTourPage(uid: Get.parameters['uid'] ?? ''),
    ),
  ];
}
