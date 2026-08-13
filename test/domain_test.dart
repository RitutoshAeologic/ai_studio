import 'package:flutter_test/flutter_test.dart';
import 'package:ai_studio/domain/entities/user_entity.dart';
import 'package:ai_studio/domain/entities/wallet_entity.dart';
import 'package:ai_studio/domain/entities/job_entity.dart';

void main() {
  group('Domain Entities & Enums', () {
    test('UserEntity creates and copies correctly', () {
      final user = UserEntity(
        uid: 'u1',
        email: 'test@example.com',
        displayName: 'Test User',
        creditBalance: 100,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(user.uid, 'u1');
      expect(user.creditBalance, 100);

      final updated = user.copyWith(creditBalance: 97);
      expect(updated.creditBalance, 97);
      expect(updated.uid, 'u1');
    });

    test('WalletEntity properties and copyWith', () {
      final now = DateTime.now();
      final wallet = WalletEntity(
        userId: 'u1',
        balance: 100,
        updatedAt: now,
      );

      expect(wallet.userId, 'u1');
      expect(wallet.balance, 100);

      final updated = wallet.copyWith(balance: 105);
      expect(updated.balance, 105);
    });

    test('JobType and JobStatus string parsing', () {
      expect(JobType.fromString('IMAGE_GEN'), JobType.imageGen);
      expect(JobType.fromString('IMAGE_3D'), JobType.meshGen);
      expect(JobType.fromString('MESH_GEN'), JobType.meshGen);
      expect(JobType.fromString('BG_REMOVAL'), JobType.bgRemoval);
      expect(JobType.fromString('THEME_CHANGE'), JobType.themeChange);

      expect(JobStatus.fromString('pending'), JobStatus.pending);
      expect(JobStatus.fromString('deducting_credits'), JobStatus.deductingCredits);
      expect(JobStatus.fromString('queued'), JobStatus.queued);
      expect(JobStatus.fromString('processing'), JobStatus.processing);
      expect(JobStatus.fromString('completed'), JobStatus.completed);
      expect(JobStatus.fromString('error'), JobStatus.error);

      expect(JobStatus.completed.isTerminal, true);
      expect(JobStatus.error.isTerminal, true);
      expect(JobStatus.processing.isActive, true);
      expect(JobStatus.idle.isActive, false);
    });

    test('JobParams serialization', () {
      const p1 = JobParams(userPrompt: 'Cyberpunk city');
      final json1 = p1.toJson();
      expect(json1['userPrompt'], 'Cyberpunk city');
      expect(json1['themeId'], null);

      final parsed1 = JobParams.fromJson(json1);
      expect(parsed1.userPrompt, 'Cyberpunk city');

      const p2 = JobParams(themeId: 42);
      final json2 = p2.toJson();
      expect(json2['themeId'], 42);
      expect(json2['userPrompt'], null);
    });
  });
}
