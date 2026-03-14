# lex-appraisal

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Lazarus's Cognitive Appraisal Theory for brain-modeled agentic AI. Models how the agent evaluates events across primary dimensions (relevance, goal congruence, importance) and secondary dimensions (coping potential, control expectation, future expectancy) to derive emotional responses and select coping strategies.

## Gem Info

- **Gem name**: `lex-appraisal`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::Appraisal`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/appraisal/
  appraisal.rb              # Main extension module
  version.rb                # VERSION = '0.1.0'
  client.rb                 # Client wrapper
  helpers/
    constants.rb            # Dimensions, emotion mappings, coping types, limits
    appraisal.rb            # Appraisal value object
    appraisal_engine.rb     # AppraisalEngine — manages appraisals and coping strategies
  runners/
    appraisal.rb            # Runner module with 8 public methods
spec/
  (spec files)
```

## Key Constants

```ruby
MAX_APPRAISALS       = 200
MAX_COPING_STRATEGIES = 50
DEFAULT_INTENSITY    = 0.5
DECAY_RATE           = 0.02
REAPPRAISAL_DISCOUNT = 0.3   # intensity reduction on reappraisal

PRIMARY_DIMENSIONS   = %i[relevance goal_congruence goal_importance]
SECONDARY_DIMENSIONS = %i[coping_potential control_expectation future_expectancy]

APPRAISAL_EMOTIONS = {
  threat_low_coping:   :anxiety,
  threat_high_coping:  :challenge,
  loss:                :sadness,
  goal_incongruent:    :anger,
  goal_congruent:      :joy,
  irrelevant:          :indifference,
  unexpected_positive: :surprise,
  moral_violation:     :disgust
}

COPING_TYPES = %i[problem_focused emotion_focused meaning_focused avoidant social_support]
```

## Runners

### `Runners::Appraisal`

All methods delegate to a private `@engine` (`Helpers::AppraisalEngine` instance). All methods wrap in `rescue StandardError` and return `{ success: false, error: message }` on failure.

- `appraise_event(event:, primary:, secondary:, domain: nil)` — appraise an event against primary and secondary dimensions; derives emotional response
- `reappraise_event(appraisal_id:, new_primary:, new_secondary:)` — re-evaluate a prior appraisal; applies `REAPPRAISAL_DISCOUNT` to intensity
- `select_coping_strategy(appraisal_id:, coping_type:)` — assign a coping strategy to an appraisal
- `add_coping_strategy(name:, coping_type:, effectiveness:)` — register a coping strategy
- `evaluate_coping(appraisal_id:)` — evaluate effectiveness of the selected coping strategy
- `emotional_pattern` — distribution of derived emotional responses across appraisals
- `update_appraisal` — decay all appraisals
- `appraisal_stats` — stats: total, unresolved count, history size, emotional pattern

## Helpers

### `Helpers::AppraisalEngine`
Core engine. Stores `@appraisals` hash and `@coping_strategies` hash. `emotional_pattern` aggregates emotion types across all appraisals. `unresolved` returns appraisals without a selected coping strategy.

### `Helpers::Appraisal`
Value object storing the event, primary/secondary dimension scores, derived emotion, coping selection, intensity, and domain.

## Integration Points

This extension is the bridge between event perception and emotional response. It feeds directly into lex-emotion: the derived emotion from `appraise_event` provides the typed emotional signal that lex-emotion's `evaluate_valence` can process. The `emotional_pattern` output informs lex-dream's agenda_formation phase about recurrent stressors. Reappraisal (`reappraise_event`) models cognitive emotion regulation.

## Development Notes

- Primary and secondary dimensions are passed as hashes (`{ relevance: 0.8, goal_congruence: 0.6, goal_importance: 0.7 }`) — the engine maps these to the emotion table
- `REAPPRAISAL_DISCOUNT = 0.3` means reappraising reduces intensity by 30% — models the stress-reduction benefit of cognitive reframing
- All methods include `rescue StandardError` blocks, making this extension unusually defensive about error propagation
