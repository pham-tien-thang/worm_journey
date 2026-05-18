# Codex Rule: Flutter Flame Performance

Apply this rule when editing `lib/game/**`, `lib/components/**`, or gameplay UI in
`lib/widgets/**`.

## Core Principle

Preserve gameplay behavior first. Performance edits must not change level rules,
spawn timing, mission progress, collision outcomes, buff duration, revive logic,
or victory/game-over conditions unless the task explicitly asks for a gameplay
change.

## Flame Game Loop

- Keep `update(dt)` deterministic and allocation-light. Do not create avoidable
  `List.unmodifiable`, `TextPainter`, `Paint`, `Random`, `PictureRecorder`,
  string grid keys, or large temporary lists inside per-frame paths.
- Do not perform async work, asset loading, JSON parsing, shared preferences,
  network calls, or file I/O from `update` or `render`.
- For grid/entity lookup, use indexed manager APIs such as `MapEntityManager`
  instead of scanning every entity each frame.
- Use scalar math and mutate existing `Vector2` values with `setValues` in hot
  movement/camera paths when the object does not need to be replaced.
- Gate periodic logic with accumulators/timers. Do not run spawn, mission, or
  expensive visibility checks every frame unless the result can actually change.

## Render Rules

- Cache static rendering work. Backgrounds, repeated emoji/icon text, paints,
  and layout metrics should be prepared in `onLoad`, lazily once, or rebuilt only
  on resize/config changes.
- Never construct `TextPainter` inside `render` for static component labels.
  Re-layout only when `size`, icon, or font scale changes.
- Load sprites in `onLoad` using Flame image cache. Do not call `Sprite.load`
  from `render` or every state transition.
- Avoid `findParent` inside `render` for components that render every frame.
  Cache the parent reference in `onLoad` if needed.
- Dispose cached `ui.Picture` objects when invalidating or removing a component.

## Flutter Overlay And Rebuilds

- Keep `GameWidget` stable. Do not recreate the `WormJourneyGame` from ordinary
  overlay/HUD rebuilds.
- HUD polling must compare visible data before `setState`; avoid rebuilding
  every poll when the displayed second, mission, buff, or coin value is unchanged.
- Prefer `ValueListenableBuilder`, `AnimatedBuilder`, or scoped state for small
  animated UI regions instead of rebuilding the whole game scaffold.
- Do not put gameplay state mutations in `build`; use callbacks, timers,
  listeners, or game methods.

## Scaling New Levels And Logic

- New level mechanics should add indexed state to managers when they introduce
  frequent lookup by grid, type, category, or visibility.
- New components must document whether they are static, animated, or event-driven
  and cache render resources accordingly.
- Before merging gameplay performance work, run:
  `flutter analyze --no-fatal-infos --no-fatal-warnings`.
- If tests exist, run the relevant Flutter tests. If the project test scaffold is
  broken or empty, report that explicitly instead of claiming test coverage.
