import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/category.dart';
import '../bloc/categories_list_bloc.dart';
import '../widgets/category_folder_view.dart';

/// Page d'un dossier ouvert (récursive) : réutilise le bloc partagé de l'écran
/// racine via `BlocProvider.value` et affiche les sous-dossiers + recettes du
/// [category] courant. Ouvrir un sous-dossier repousse cette même page.
class CategoryFolderPage extends StatelessWidget {
  const CategoryFolderPage({
    super.key,
    required this.bloc,
    required this.category,
  });

  final CategoriesListBloc bloc;
  final Category category;

  static Route<void> route({
    required CategoriesListBloc bloc,
    required Category category,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) => CategoryFolderPage(bloc: bloc, category: category),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: CategoryFolderView(parent: category),
    );
  }
}
