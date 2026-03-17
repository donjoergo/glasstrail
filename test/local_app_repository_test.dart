import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:glasstrail/src/models.dart';
import 'package:glasstrail/src/repository/local_app_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalAppRepository', () {
    late LocalAppRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = LocalAppRepository(await SharedPreferences.getInstance());
    });

    test('keeps custom drinks and entries isolated per user', () async {
      final userOne = await repository.signUp(
        email: 'one@example.com',
        password: 'secret',
        nickname: 'one',
        displayName: 'User One',
      );
      await repository.saveCustomDrink(
        userId: userOne.id,
        name: 'Office Brew',
        category: DrinkCategory.nonAlcoholic,
        volumeMl: 300,
      );
      await repository.addDrinkEntry(
        user: userOne,
        drink: DrinkDefinition(
          id: 'office-brew',
          name: 'Office Brew',
          category: DrinkCategory.nonAlcoholic,
          volumeMl: 300,
          ownerUserId: userOne.id,
        ),
      );
      await repository.signOut();

      final userTwo = await repository.signUp(
        email: 'two@example.com',
        password: 'secret',
        nickname: 'two',
        displayName: 'User Two',
      );

      final userOneDrinks = await repository.loadCustomDrinks(userOne.id);
      final userTwoDrinks = await repository.loadCustomDrinks(userTwo.id);
      final userOneEntries = await repository.loadEntries(userOne.id);
      final userTwoEntries = await repository.loadEntries(userTwo.id);

      expect(userOneDrinks, hasLength(1));
      expect(userTwoDrinks, isEmpty);
      expect(userOneEntries, hasLength(1));
      expect(userTwoEntries, isEmpty);
    });

    test('restores the active session and rejects duplicate emails', () async {
      final user = await repository.signUp(
        email: 'duplicate@example.com',
        password: 'secret',
        nickname: 'dup',
        displayName: 'Duplicate',
      );

      final restored = await repository.restoreSession();

      expect(restored?.id, user.id);
      expect(
        () => repository.signUp(
          email: 'duplicate@example.com',
          password: 'secret',
          nickname: 'dup-2',
          displayName: 'Duplicate Two',
        ),
        throwsA(isA<AppException>()),
      );
    });
  });
}
