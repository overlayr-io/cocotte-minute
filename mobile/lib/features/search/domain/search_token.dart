import 'package:equatable/equatable.dart';

import '../../categories/domain/category.dart';
import '../../people/domain/person.dart';
import '../../tags/domain/tag.dart';

/// Les trois dimensions filtrables de la recherche avancée, chacune déclenchée
/// par un caractère dans la barre (`/` dossier, `#` tag, `@` personne).
enum SearchDimension {
  folder('/'),
  tag('#'),
  person('@');

  const SearchDimension(this.trigger);

  /// Caractère déclencheur tapé dans la barre pour ouvrir ce menu.
  final String trigger;

  static SearchDimension? fromTrigger(String char) {
    for (final d in SearchDimension.values) {
      if (d.trigger == char) return d;
    }
    return null;
  }
}

/// Un critère posé dans la barre, affiché en pastille sous la ligne de saisie.
/// Cumulables (ET). Chaque sous-type porte le modèle source pour l'affichage.
sealed class SearchToken extends Equatable {
  const SearchToken();

  /// Identifiant de l'entité filtrée (id de dossier / tag / personne).
  String get id;

  SearchDimension get dimension;

  /// Libellé affiché dans la pastille.
  String get label;
}

class FolderToken extends SearchToken {
  const FolderToken(this.category);

  final Category category;

  @override
  String get id => category.id;

  @override
  SearchDimension get dimension => SearchDimension.folder;

  @override
  String get label => category.name;

  @override
  List<Object?> get props => [category.id];
}

class TagToken extends SearchToken {
  const TagToken(this.tag);

  final Tag tag;

  @override
  String get id => tag.id;

  @override
  SearchDimension get dimension => SearchDimension.tag;

  @override
  String get label => tag.name;

  @override
  List<Object?> get props => [tag.id];
}

class PersonToken extends SearchToken {
  const PersonToken(this.person);

  final Person person;

  @override
  String get id => person.id;

  @override
  SearchDimension get dimension => SearchDimension.person;

  @override
  String get label => person.firstName;

  @override
  List<Object?> get props => [person.id];
}
