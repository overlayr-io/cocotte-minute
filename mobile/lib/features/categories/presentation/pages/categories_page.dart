import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../data/categories_repository.dart';
import '../bloc/categories_list_bloc.dart';
import '../widgets/category_folder_view.dart';

/// Écran "Catégories" (racine de l'arborescence). Crée le bloc partagé et
/// affiche les dossiers racines ; les pages de dossier sont poussées avec ce
/// même bloc (`BlocProvider.value`) pour une source de vérité unique.
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const CategoriesPage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CategoriesListBloc(repository: sl<CategoriesRepository>())
        ..add(const CategoriesRequested()),
      child: const CategoryFolderView(),
    );
  }
}
