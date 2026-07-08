import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/error_view.dart';
import '../../data/ingredients_repository.dart';
import '../../domain/ingredient.dart';
import '../bloc/ingredient_detail_bloc.dart';
import '../widgets/ingredient_visual_field.dart';
import '../widgets/unit_selector.dart';

/// Détail / édition d'un ingrédient utilisateur. Renvoie `true` si enregistré,
/// `'deleted'` si supprimé — pour que la liste appelante se rafraîchisse.
class IngredientDetailPage extends StatelessWidget {
  const IngredientDetailPage({super.key, required this.id});

  final String id;

  static Route<Object?> route(String id) {
    return MaterialPageRoute<Object?>(builder: (_) => IngredientDetailPage(id: id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          IngredientDetailBloc(repository: sl<IngredientsRepository>())
            ..add(IngredientDetailRequested(id)),
      child: _DetailView(id: id),
    );
  }
}

class _DetailView extends StatefulWidget {
  const _DetailView({required this.id});

  final String id;

  @override
  State<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<_DetailView> {
  final _nameController = TextEditingController();
  IngredientUnit _unit = IngredientUnit.gramme;
  String? _imageUrl;
  String? _emoji;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _initFrom(Ingredient ingredient) {
    if (_initialized) return;
    _nameController.text = ingredient.name;
    _unit = ingredient.unit;
    _imageUrl = ingredient.imageUrl;
    _emoji = ingredient.emoji;
    _initialized = true;
  }

  void _save(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.ingredientNameRequired)));
      return;
    }
    context.read<IngredientDetailBloc>().add(
          IngredientDetailSaveRequested(
            name: name,
            unit: _unit,
            emoji: _emoji,
            imageUrl: _imageUrl,
          ),
        );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.ingredientDeleteConfirmTitle),
        content: Text(l10n.ingredientDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE0554A)),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<IngredientDetailBloc>().add(const IngredientDetailDeleteRequested());
    }
  }

  Future<void> _addAlternative(
    BuildContext context,
    IngredientDetail detail,
  ) async {
    final excluded = {detail.ingredient.id, ...detail.alternatives.map((a) => a.id)};
    final picked = await _showAlternativePicker(context, excluded);
    if (picked != null && context.mounted) {
      context.read<IngredientDetailBloc>().add(IngredientAlternativeAdded(picked.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ingredientDetailTitle)),
      body: BlocConsumer<IngredientDetailBloc, IngredientDetailState>(
        listener: (context, state) {
          switch (state) {
            case IngredientDetailSaved():
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(l10n.ingredientSavedToast)));
              Navigator.of(context).pop(true);
            case IngredientDetailDeleted():
              Navigator.of(context).pop('deleted');
            case IngredientDetailActionFailure(:final message):
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(message)));
            case IngredientDetailLoaded(:final detail):
              _initFrom(detail.ingredient);
            default:
              break;
          }
        },
        builder: (context, state) {
          return switch (state) {
            IngredientDetailError(:final message) => ErrorView(
                message: message,
                onRetry: () => context
                    .read<IngredientDetailBloc>()
                    .add(IngredientDetailRequested(widget.id)),
              ),
            IngredientDetailLoaded(:final detail, :final mutating) =>
              _buildForm(context, detail, mutating, l10n),
            _ => const Center(child: CircularProgressIndicator()),
          };
        },
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    IngredientDetail detail,
    bool mutating,
    AppLocalizations l10n,
  ) {
    return AbsorbPointer(
      absorbing: mutating,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          IngredientVisualField(
            emoji: _emoji,
            imageUrl: _imageUrl,
            onEmojiChanged: (emoji) => setState(() {
              _emoji = emoji;
              _imageUrl = null;
            }),
            onImageUploaded: (url) => setState(() {
              _imageUrl = url;
              _emoji = null;
            }),
          ),
          const SizedBox(height: 20),
          if (detail.ingredient.isImported) ...[
            _SystemNote(text: l10n.ingredientFromSystem),
            const SizedBox(height: 16),
          ],
          _FieldLabel(l10n.ingredientFieldName),
          const SizedBox(height: 7),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.card,
              enabledBorder: _border(AppColors.border),
              focusedBorder: _border(AppColors.primary),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          _FieldLabel(l10n.ingredientFieldUnit),
          const SizedBox(height: 9),
          UnitSelector(
            selected: _unit,
            onChanged: (u) => setState(() => _unit = u),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _FieldLabel(l10n.ingredientSectionAlternatives),
              Text(
                l10n.ingredientAlternativesHint,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 9),
          _Alternatives(
            alternatives: detail.alternatives,
            onAdd: () => _addAlternative(context, detail),
            onRemove: (alt) => context
                .read<IngredientDetailBloc>()
                .add(IngredientAlternativeRemoved(alt.id)),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () => _save(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                l10n.ingredientSave,
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _confirmDelete(context),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text(
                l10n.ingredientDelete,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE0554A),
                backgroundColor: const Color(0xFFFDF1EF),
                side: const BorderSide(color: Color(0xFFF4CFC9)),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color),
    );
  }

  /// Sélecteur d'alternative parmi mes autres ingrédients.
  Future<Ingredient?> _showAlternativePicker(
    BuildContext context,
    Set<String> excluded,
  ) {
    final l10n = AppLocalizations.of(context);
    return showModalBottomSheet<Ingredient>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FutureBuilder<List<Ingredient>>(
          future: sl<IngredientsRepository>().fetchMine(),
          builder: (context, snapshot) {
            final candidates = (snapshot.data ?? const <Ingredient>[])
                .where((i) => !excluded.contains(i.id))
                .toList();
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDAD5C8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.ingredientPickAlternativeTitle,
                    style: const TextStyle(
                      fontFamily: AppFonts.display,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (candidates.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        l10n.ingredientNoCandidate,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: candidates.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final c = candidates[i];
                          return ListTile(
                            onTap: () => Navigator.of(sheetContext).pop(c),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            tileColor: AppColors.card,
                            leading: _AltAvatar(ingredient: c, size: 40),
                            title: Text(
                              c.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            trailing: Text(
                              unitLabel(l10n, c.unit),
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12.5,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Vignette d'une alternative : emoji, image, ou icône de repli.
class _AltAvatar extends StatelessWidget {
  const _AltAvatar({required this.ingredient, this.size = 26});

  final Ingredient ingredient;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size >= 36 ? 12 : size);
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: radius,
      ),
      child: ingredient.imageUrl != null
          ? AppNetworkImage(ingredient.imageUrl!, decodeWidth: size * 2)
          : ingredient.emoji != null
              ? Text(ingredient.emoji!, style: TextStyle(fontSize: size * 0.56))
              : Icon(Icons.eco_outlined, size: size * 0.58, color: AppColors.primary),
    );
  }
}

class _SystemNote extends StatelessWidget {
  const _SystemNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EAD6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF8A7A4E)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A7A4E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _Alternatives extends StatelessWidget {
  const _Alternatives({
    required this.alternatives,
    required this.onAdd,
    required this.onRemove,
  });

  final List<Ingredient> alternatives;
  final VoidCallback onAdd;
  final ValueChanged<Ingredient> onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final alt in alternatives)
          Container(
            padding: const EdgeInsets.fromLTRB(7, 6, 8, 6),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AltAvatar(ingredient: alt),
                const SizedBox(width: 8),
                Text(
                  alt.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => onRemove(alt),
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: Color(0xFF9A9482)),
                ),
              ],
            ),
          ),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFC4BEAD), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, size: 15, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context).ingredientAddAlternative,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
