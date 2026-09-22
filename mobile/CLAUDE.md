# Development & UI Architecture Guidelines

## 1. Safe-Area Aware Bottom Padding (MANDATORY)
Device navigation bars (Android 3-button navigation, gesture bars, iOS home indicator) will overlap, obscure, or crop UI elements if safe area padding is omitted.

- **Bottom Sheets (`showModalBottomSheet`)**:
  - Always set `useSafeArea: true`.
  - Set `isScrollControlled: true` when sheets contain action buttons, lists, or text fields.
  - Wrap content in `SafeArea(top: false, child: ...)` or explicitly calculate bottom padding:
    ```dart
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + (bottomInset > 0 ? bottomInset : 10)),
      child: ...,
    )
    ```
  - Never allow primary action buttons (like "Apply Filters", "Save", "Submit") to sit flush at the bottom edge without safe area clearance.

- **Scrollables & Lists (`ListView`, `SingleChildScrollView`, `GridView`)**:
  - When a screen has a `FloatingActionButton` (FAB) or is hosted in a shell with a `BottomNavigationBar`, the list bottom padding **must** clear both the widget and the device safe area:
    ```dart
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    ListView.builder(
      padding: EdgeInsets.fromLTRB(20, 8, 20, safeBottom + 108), // 108dp ensures full clearance above FAB/bar
      ...
    );
    ```
  - For standard lists without a FAB, use at least `safeBottom + 24` to ensure the final card is never clipped by the system navigation bar.

---

## 2. Overflow Prevention in Rows & Flex Layouts (MANDATORY)
Yellow/black hazard stripes (`A RenderFlex overflowed by X pixels`) degrade UX and break on different screen sizes and display scalings.

- **Title / Stat Header Rows**:
  - In horizontal `Row`s containing text alongside stat cards, badges, or buttons, **always** wrap the text column in `Expanded`:
    ```dart
    Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Members', style: TextStyle(...)),
              Text(
                'Manage and view all gym members',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TotalMembersCard(...),
      ],
    )
    ```
  - Never place unconstrained text columns in a `Row` with other fixed/intrinsic width widgets.

- **Multi-Column Card Details (e.g. 3-column stats rows)**:
  - Each column in a multi-column row must be `Expanded`.
  - Text elements inside must have `maxLines: 1` and `overflow: TextOverflow.ellipsis`.
  - Icon-and-text headers inside columns should use `Flexible(child: Text(..., maxLines: 1, overflow: TextOverflow.ellipsis))` next to icons.

- **Chips and Filter Rows**:
  - Never use an unconstrained horizontal `Row` for variable-length filter options.
  - Always use `SingleChildScrollView(scrollDirection: Axis.horizontal, ...)` or `Wrap(spacing: ..., runSpacing: ...)`.

---

## 3. Keyboard & Inset Awareness
- Any form or modal containing `TextField`s must handle keyboard appearance:
  - Set `resizeToAvoidBottomInset: true` on `Scaffold`.
  - Wrap form fields in `SingleChildScrollView`.
  - Use `MediaQuery.viewInsetsOf(context).bottom` to adjust scroll view clearance when keyboard opens.

---

## 4. Flutter Code Quality & Modern APIs
- **Color Opacity**: Use `.withValues(alpha: 0.16)` instead of the deprecated `.withOpacity(0.16)`.
- **Static Analysis**: Maintain **0 warnings and 0 errors** across `flutter analyze`.
- **Unit Tests**: Ensure all tests pass (`flutter test`) before declaring tasks complete.
