import 'package:flutter_test/flutter_test.dart';
import 'package:ilium_app/utils/text_normalizer.dart';

void main() {
  group('TextNormalizer', () {
    group('normalizeMatiere', () {
      test('normalise les variantes de mathématiques', () {
        expect(TextNormalizer.normalizeMatiere('maths'), 'Mathématiques');
        expect(TextNormalizer.normalizeMatiere('MATH'), 'Mathématiques');
        expect(TextNormalizer.normalizeMatiere('mathematiques'), 'Mathématiques');
        expect(TextNormalizer.normalizeMatiere('mathématique'), 'Mathématiques');
      });

      test('normalise les variantes de français', () {
        expect(TextNormalizer.normalizeMatiere('francais'), 'Français');
        expect(TextNormalizer.normalizeMatiere('FRANÇAIS'), 'Français');
        expect(TextNormalizer.normalizeMatiere('fran'), 'Français');
      });

      test('normalise les variantes de physique-chimie', () {
        expect(TextNormalizer.normalizeMatiere('physique'), 'Physique-Chimie');
        expect(TextNormalizer.normalizeMatiere('chimie'), 'Physique-Chimie');
        expect(TextNormalizer.normalizeMatiere('PC'), 'Physique-Chimie');
        expect(TextNormalizer.normalizeMatiere('physique chimie'), 'Physique-Chimie');
      });

      test('normalise les variantes de SVT', () {
        expect(TextNormalizer.normalizeMatiere('svt'), 'SVT');
        expect(TextNormalizer.normalizeMatiere('biologie'), 'SVT');
        expect(TextNormalizer.normalizeMatiere('bio'), 'SVT');
      });

      test('garde les matières inconnues avec première lettre majuscule', () {
        expect(TextNormalizer.normalizeMatiere('japonais'), 'Japonais');
        expect(TextNormalizer.normalizeMatiere('latin ancien'), 'Latin Ancien');
      });
    });

    group('normalizeNiveau', () {
      test('normalise les niveaux du collège', () {
        expect(TextNormalizer.normalizeNiveau('6'), '6ème');
        expect(TextNormalizer.normalizeNiveau('6eme'), '6ème');
        expect(TextNormalizer.normalizeNiveau('sixieme'), '6ème');
        expect(TextNormalizer.normalizeNiveau('5'), '5ème');
        expect(TextNormalizer.normalizeNiveau('cinquieme'), '5ème');
      });

      test('normalise les niveaux du lycée', () {
        expect(TextNormalizer.normalizeNiveau('2nde'), '2nde');
        expect(TextNormalizer.normalizeNiveau('seconde'), '2nde');
        expect(TextNormalizer.normalizeNiveau('1ere'), '1ère');
        expect(TextNormalizer.normalizeNiveau('premiere'), '1ère');
        expect(TextNormalizer.normalizeNiveau('terminale'), 'Terminale');
        expect(TextNormalizer.normalizeNiveau('term'), 'Terminale');
      });

      test('normalise les spécialités', () {
        expect(TextNormalizer.normalizeNiveau('term'), 'Terminale');
        expect(TextNormalizer.normalizeNiveau('terminale'), 'Terminale');
        expect(TextNormalizer.normalizeNiveau('1ere'), '1ère');
        expect(TextNormalizer.normalizeNiveau('premiere'), '1ère');
      });

      test('normalise les niveaux post-bac', () {
        expect(TextNormalizer.normalizeNiveau('L1'), 'L1');
        expect(TextNormalizer.normalizeNiveau('licence 1'), 'L1');
        expect(TextNormalizer.normalizeNiveau('M1'), 'M1');
        expect(TextNormalizer.normalizeNiveau('master'), 'M1');
        expect(TextNormalizer.normalizeNiveau('bts'), 'BTS');
      });

      test('garde les niveaux inconnus avec première lettre majuscule', () {
        expect(TextNormalizer.normalizeNiveau('prepa'), 'Prepa');
        expect(TextNormalizer.normalizeNiveau('grande école'), 'Grande École');
      });
    });
  });
}