# lex-appraisal

Lazarus's Cognitive Appraisal Theory for brain-modeled agentic AI.

## What It Does

Models how the agent evaluates events to determine their emotional significance. Based on Lazarus's two-stage appraisal process: primary appraisal assesses relevance, goal alignment, and importance; secondary appraisal assesses coping capacity, control, and future expectancy. The combination determines the emotional response (anxiety, joy, anger, challenge, etc.) and guides coping strategy selection.

## Core Concept: Two-Stage Appraisal

```ruby
# Stage 1: Primary appraisal (how relevant is this event to my goals?)
# Stage 2: Secondary appraisal (can I handle it?)
# Combined -> emotional response

result = client.appraise_event(
  event: 'service outage in production',
  primary:   { relevance: 0.95, goal_congruence: -0.8, goal_importance: 0.9 },
  secondary: { coping_potential: 0.3, control_expectation: 0.4, future_expectancy: 0.5 },
  domain: :infrastructure
)
# => { appraisal: { emotion: :anxiety, intensity: 0.8, ... } }
```

## Usage

```ruby
client = Legion::Extensions::Appraisal::Client.new

# Register a coping strategy
client.add_coping_strategy(name: :incident_playbook, coping_type: :problem_focused, effectiveness: 0.85)

# Appraise an event
result = client.appraise_event(event: 'deployment failed', primary: {...}, secondary: {...})

# Reappraise with new information (reduces intensity by 30%)
client.reappraise_event(
  appraisal_id: result[:appraisal][:id],
  new_primary: { relevance: 0.5, goal_congruence: 0.2, goal_importance: 0.6 },
  new_secondary: { coping_potential: 0.8, control_expectation: 0.7, future_expectancy: 0.8 }
)

# Select a coping strategy
client.select_coping_strategy(appraisal_id: id, coping_type: :problem_focused)

# View emotional patterns
client.emotional_pattern
# => { anxiety: 3, challenge: 2, joy: 1 }
```

## Integration

Feeds into lex-emotion: derived emotions provide typed signals for valence evaluation. Reappraisal models cognitive emotion regulation. `emotional_pattern` informs lex-dream's agenda formation about recurring stressors.

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
