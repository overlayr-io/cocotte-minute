import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/i18n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/search_token.dart';
import '../bloc/search_cubit.dart';
import 'search_colors.dart';
import 'search_pastille.dart';

/// Barre de recherche « à la Notion » : une ligne de saisie (dont le texte prend
/// la couleur de la dimension en cours) surmontant les pastilles posées. Bordure
/// verte quand on tape, neutre au repos.
class SearchField extends StatefulWidget {
  const SearchField({super.key, required this.state});

  final SearchState state;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.state.rawInput);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Resynchronise le champ quand le cubit a modifié la saisie hors frappe
    // (pastille ajoutée → champ vidé, bouton déclencheur → préfixe inséré).
    if (_controller.text != widget.state.rawInput) {
      _controller.value = TextEditingValue(
        text: widget.state.rawInput,
        selection: TextSelection.collapsed(offset: widget.state.rawInput.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = widget.state;
    final cubit = context.read<SearchCubit>();
    final active = state.isTyping;
    final inputColor = state.openMenu != null
        ? SearchColors.accentOf(state.openMenu!)
        : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: active ? SearchColors.folder : const Color(0xFFE4DFD4),
          width: active ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: active ? 0.12 : 0.09),
            blurRadius: active ? 22 : 18,
            offset: Offset(0, active ? 8 : 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 19,
                color: active ? SearchColors.folder : AppColors.textMuted,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  // Clavier ouvert dès l'arrivée sur l'écran : la recherche
                  // s'utilise au doigt levé, sans tap supplémentaire.
                  autofocus: true,
                  onChanged: cubit.queryChanged,
                  cursorColor: SearchColors.folder,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: state.openMenu != null
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: inputColor,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: l10n.searchHint,
                    hintStyle: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFFB0AA9A),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              // Icône filtre commune avec la barre de l'accueil (fond
              // transparent) : ramène simplement le focus sur le champ.
              GestureDetector(
                onTap: _focusNode.requestFocus,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.tune_rounded, size: 20, color: AppColors.primary),
                ),
              ),
            ],
          ),
          if (state.tokens.isNotEmpty) ...[
            const SizedBox(height: 9),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final token in state.tokens)
                  SearchPastille(
                    token: token,
                    onRemove: () => cubit.removeToken(token),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Les trois boutons déclencheurs sous le champ : ouvrent le menu d'une dimension
/// sans avoir à taper. Le bouton de la dimension active est teinté.
class SearchTriggerButtons extends StatelessWidget {
  const SearchTriggerButtons({super.key, required this.state});

  final SearchState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        _TriggerButton(
          dimension: SearchDimension.folder,
          label: l10n.searchTriggerFolder,
          active: state.openMenu == SearchDimension.folder,
        ),
        const SizedBox(width: 8),
        _TriggerButton(
          dimension: SearchDimension.tag,
          label: l10n.searchTriggerTag,
          active: state.openMenu == SearchDimension.tag,
        ),
        const SizedBox(width: 8),
        _TriggerButton(
          dimension: SearchDimension.person,
          label: l10n.searchTriggerPerson,
          active: state.openMenu == SearchDimension.person,
        ),
      ],
    );
  }
}

class _TriggerButton extends StatelessWidget {
  const _TriggerButton({
    required this.dimension,
    required this.label,
    required this.active,
  });

  final SearchDimension dimension;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final accent = SearchColors.accentOf(dimension);
    return GestureDetector(
      onTap: () => context.read<SearchCubit>().openMenu(dimension),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: active ? SearchColors.tintOf(dimension) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? SearchColors.borderOf(dimension) : AppColors.border,
            width: active ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dimension.trigger,
              style: TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                color: active ? accent : const Color(0xFF8A8574),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: active ? accent : const Color(0xFF8A8574),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
