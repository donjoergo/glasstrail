import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:glasstrail/l10n/app_localizations.dart';
import 'package:glasstrail/src/models.dart';

void main() {
  group('AppUnit', () {
    test('rounds ml display values to whole milliliters', () {
      expect(AppUnit.ml.formatVolume(42.2), '42 ml');
      expect(AppUnit.ml.formatVolume(42.8), '43 ml');
      expect(AppUnit.ml.formatVolumeInput(42.2), '42');
      expect(AppUnit.ml.formatVolumeInput(42.8), '43');
    });

    test('keeps oz display values fractional when needed', () {
      expect(AppUnit.oz.formatVolume(330), '11.2 oz');
      expect(AppUnit.oz.formatVolumeInput(330), '11.2');
    });
  });

  group('UserSettings', () {
    test('reads snake_case keys from remote rows', () {
      final settings = UserSettings.fromJson(<String, dynamic>{
        'theme_preference': 'dark',
        'locale_code': 'de',
        'unit': 'oz',
        'handedness': 'left',
        'hidden_global_drink_ids': <String>['beer-pils'],
        'hidden_global_drink_categories': <String>['beer'],
        'global_drink_order_overrides': <String, List<String>>{
          'beer': <String>['beer-ipa', 'beer-pils'],
        },
      });

      expect(settings.themePreference, AppThemePreference.dark);
      expect(settings.localeCode, 'de');
      expect(settings.unit, AppUnit.oz);
      expect(settings.handedness, AppHandedness.left);
      expect(settings.hiddenGlobalDrinkIds, <String>['beer-pils']);
      expect(settings.hiddenGlobalDrinkCategories, <DrinkCategory>[
        DrinkCategory.beer,
      ]);
      expect(settings.globalDrinkOrderOverrides[DrinkCategory.beer], <String>[
        'beer-ipa',
        'beer-pils',
      ]);
    });
  });

  group('AppUser', () {
    test('normalizes birthdays to month and day only', () {
      final user = AppUser.fromJson(<String, dynamic>{
        'id': 'user-1',
        'email': 'alice@example.com',
        'displayName': 'Alice Example',
        'birthday': '1994-07-16',
      });

      expect(user.birthday, DateTime(2000, 7, 16));
      expect(user.toJson()['birthday'], '2000-07-16T00:00:00.000');
    });
  });

  group('AppNotification', () {
    test('reads generalized snake_case notification rows', () {
      final notification = AppNotification.fromJson(<String, dynamic>{
        'notification_id': 'notification-1',
        'recipient_user_id': 'recipient-1',
        'sender_user_id': 'sender-1',
        'sender_display_name': 'Sender User',
        'image_path': 'sender/profile.png',
        'notification_type': 'friend_request_sent',
        'template_args': <String, String>{'senderDisplayName': 'Sender User'},
        'created_at': '2026-04-26T10:00:00Z',
        'metadata': <String, dynamic>{'route': '/profile'},
      });

      expect(notification.senderUserId, 'sender-1');
      expect(notification.senderDisplayName, 'Sender User');
      expect(notification.imagePath, 'sender/profile.png');
      expect(notification.type, AppNotificationTypes.friendRequestSent);
      expect(notification.templateArgs['senderDisplayName'], 'Sender User');
      expect(
        notification.title(lookupAppLocalizations(const Locale('de'))),
        lookupAppLocalizations(
          const Locale('de'),
        ).notificationFriendRequestSentTitle('Sender User'),
      );
      expect(
        notification.text(lookupAppLocalizations(const Locale('en'))),
        lookupAppLocalizations(
          const Locale('en'),
        ).notificationFriendRequestSentBody,
      );
      expect(notification.metadata['route'], '/profile');
    });

    test('uses sender display name when template args omit sender', () {
      final notification = AppNotification.fromJson(<String, dynamic>{
        'id': 'notification-1',
        'recipientUserId': 'recipient-1',
        'senderDisplayName': 'Sender User',
        'type': AppNotificationTypes.friendRequestSent,
        'templateArgs': const <String, dynamic>{},
      });

      expect(notification.templateSenderDisplayName, 'Sender User');
      expect(
        notification.title(lookupAppLocalizations(const Locale('en'))),
        lookupAppLocalizations(
          const Locale('en'),
        ).notificationFriendRequestSentTitle('Sender User'),
      );
    });

    test('supports notifications without text', () {
      final notification = AppNotification.fromJson(<String, dynamic>{
        'id': 'notification-1',
        'recipientUserId': 'recipient-1',
        'senderDisplayName': 'Sender User',
        'type': 'custom',
      });

      expect(
        notification.title(lookupAppLocalizations(const Locale('en'))),
        'Glass Trail',
      );
      expect(
        notification.text(lookupAppLocalizations(const Locale('en'))),
        isNull,
      );
    });

    test('maps friend notification types to static image urls', () {
      expect(
        AppNotificationImageUrls.imagePathForType(
          type: AppNotificationTypes.friendRequestAccepted,
          fallbackImagePath: 'sender/profile.png',
        ),
        AppNotificationImageUrls.cheers,
      );
      expect(
        AppNotificationImageUrls.imagePathForType(
          type: AppNotificationTypes.friendRequestRejected,
          fallbackImagePath: 'sender/profile.png',
        ),
        AppNotificationImageUrls.sad,
      );
      expect(
        AppNotificationImageUrls.imagePathForType(
          type: AppNotificationTypes.friendRemoved,
          fallbackImagePath: 'sender/profile.png',
        ),
        AppNotificationImageUrls.sad,
      );
      expect(
        AppNotificationImageUrls.imagePathForType(
          type: AppNotificationTypes.friendRequestSent,
          fallbackImagePath: 'sender/profile.png',
        ),
        'sender/profile.png',
      );
    });
  });

  group('PublicFriendProfile', () {
    test('reads profile image urls from public preview json', () {
      final profile = PublicFriendProfile.fromJson(<String, dynamic>{
        'id': 'profile-1',
        'displayName': 'Preview User',
        'profileImageUrl': 'https://example.com/profile.jpg',
        'profileShareCode': 'share-code',
      });

      expect(profile.profileImagePath, 'https://example.com/profile.jpg');
      expect(profile.profileShareCode, 'share-code');
    });

    test('upgrades Supabase preview image urls to https', () {
      final profile = PublicFriendProfile.fromJson(<String, dynamic>{
        'id': 'profile-1',
        'displayName': 'Preview User',
        'profileImageUrl':
            'http://project-ref.functions.supabase.co/friend-profile-preview/share-code/image',
      });

      expect(
        profile.profileImagePath,
        'https://project-ref.functions.supabase.co/friend-profile-preview/share-code/image',
      );
    });

    test('adds the functions path to Supabase REST preview image urls', () {
      final profile = PublicFriendProfile.fromJson(<String, dynamic>{
        'id': 'profile-1',
        'displayName': 'Preview User',
        'profileImageUrl':
            'https://project-ref.supabase.co/friend-profile-preview/share-code/image',
      });

      expect(
        profile.profileImagePath,
        'https://project-ref.supabase.co/functions/v1/friend-profile-preview/share-code/image',
      );
    });
  });

  group('buildDefaultDrinkCatalog', () {
    test('includes extended global drinks with stable ids and categories', () {
      final catalog = buildDefaultDrinkCatalog();

      expect(
        catalog.map((drink) => drink.category).toSet(),
        containsAll(<DrinkCategory>[
          DrinkCategory.sparklingWines,
          DrinkCategory.longdrinks,
          DrinkCategory.shots,
          DrinkCategory.appleWines,
        ]),
      );

      final champagne = catalog.firstWhere(
        (drink) => drink.id == 'sparklingWines-champagne',
      );
      expect(champagne.category, DrinkCategory.sparklingWines);
      expect(champagne.name, 'Champagne');
      expect(champagne.localizedNameDe, 'Champagner');
      expect(champagne.volumeMl, 120);

      final cocktail = catalog.firstWhere(
        (drink) => drink.id == 'cocktails-cocktail',
      );
      expect(cocktail.volumeMl, 250);

      final beer = catalog.firstWhere((drink) => drink.id == 'beer-classic');
      expect(beer.category, DrinkCategory.beer);
      expect(beer.localizedNameDe, 'Bier');
      expect(beer.volumeMl, 500);

      final beerCan = catalog.firstWhere((drink) => drink.id == 'beer-can');
      expect(beerCan.localizedNameDe, 'Dosenbier');

      final nonAlcoholicBeer = catalog.firstWhere(
        (drink) => drink.id == 'beer-non-alcoholic',
      );
      expect(nonAlcoholicBeer.category, DrinkCategory.beer);
      expect(nonAlcoholicBeer.name, 'Non-alcoholic Beer');
      expect(nonAlcoholicBeer.localizedNameDe, 'Alkoholfreies Bier');
      expect(nonAlcoholicBeer.volumeMl, 500);

      final genericShot = catalog.firstWhere(
        (drink) => drink.id == 'shots-shot',
      );
      expect(genericShot.category, DrinkCategory.shots);
      expect(genericShot.volumeMl, 20);

      final tequila = catalog.firstWhere(
        (drink) => drink.id == 'spirits-tequila',
      );
      expect(tequila.category, DrinkCategory.shots);

      final hardSeltzer = catalog.firstWhere(
        (drink) => drink.id == 'appleWines-hard-seltzer',
      );
      expect(hardSeltzer.name, 'Hard Seltzer');

      final mateTea = catalog.firstWhere(
        (drink) => drink.id == 'nonAlcoholic-mate-tea',
      );
      expect(mateTea.category, DrinkCategory.nonAlcoholic);
      expect(mateTea.name, 'Mate Tea');
      expect(mateTea.localizedNameDe, 'Mate Tee');
      expect(mateTea.volumeMl, 300);

      final clubMate = catalog.firstWhere(
        (drink) => drink.id == 'nonAlcoholic-club-mate',
      );
      expect(clubMate.category, DrinkCategory.nonAlcoholic);
      expect(clubMate.name, 'Club-Mate');
      expect(clubMate.localizedNameDe, 'Club-Mate');
      expect(clubMate.volumeMl, 500);
    });
  });

  group('DrinkEntry', () {
    test(
      'normalizes multiline location addresses into comma-separated text',
      () {
        expect(
          normalizeLocationAddress('Am Buck 19\nHerzogenaurach\nDeutschland'),
          'Am Buck 19, Herzogenaurach, Deutschland',
        );
        expect(normalizeLocationAddress('  \n  '), isNull);
      },
    );

    test('copyWith can clear comment and image independently', () {
      final entry = DrinkEntry(
        id: 'entry-1',
        userId: 'user-1',
        drinkId: 'water',
        drinkName: 'Water',
        category: DrinkCategory.nonAlcoholic,
        consumedAt: DateTime(2026, 3, 19, 12),
        volumeMl: 250,
        comment: 'Original',
        imagePath: '/tmp/original.png',
        locationLatitude: 52.52,
        locationLongitude: 13.405,
        locationAddress: 'Alexanderplatz 1, 10178 Berlin',
        importSource: 'beer_with_me',
        importSourceId: '123',
      );

      final updated = entry.copyWith(comment: 'Updated', clearImagePath: true);
      final cleared = updated.copyWith(clearComment: true);

      expect(updated.comment, 'Updated');
      expect(updated.imagePath, isNull);
      expect(updated.locationLatitude, 52.52);
      expect(updated.locationLongitude, 13.405);
      expect(updated.locationAddress, 'Alexanderplatz 1, 10178 Berlin');
      expect(updated.importSource, 'beer_with_me');
      expect(updated.importSourceId, '123');
      expect(cleared.comment, isNull);
      expect(cleared.drinkId, entry.drinkId);
      expect(cleared.consumedAt, entry.consumedAt);
    });

    test('reads snake_case location keys from remote rows', () {
      final entry = DrinkEntry.fromJson(<String, dynamic>{
        'id': 'entry-remote',
        'userId': 'user-1',
        'drinkId': 'water',
        'drinkName': 'Water',
        'category': 'nonAlcoholic',
        'consumedAt': '2026-03-19T12:00:00.000Z',
        'volume_ml': 250,
        'location_latitude': 52.52,
        'location_longitude': 13.405,
        'location_address': 'Alexanderplatz 1, 10178 Berlin',
        'import_source': 'beer_with_me',
        'import_source_id': '456',
      });

      expect(entry.volumeMl, 250);
      expect(entry.locationLatitude, 52.52);
      expect(entry.locationLongitude, 13.405);
      expect(entry.locationAddress, 'Alexanderplatz 1, 10178 Berlin');
      expect(entry.importSource, 'beer_with_me');
      expect(entry.importSourceId, '456');
    });
  });
}
