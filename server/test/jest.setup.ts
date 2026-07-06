// Charge le polyfill de métadonnées avant toute suite : requis par class-validator /
// class-transformer (décorateurs) et par l'injection NestJS dans les tests.
import 'reflect-metadata';
