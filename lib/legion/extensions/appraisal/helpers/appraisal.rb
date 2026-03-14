# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Appraisal
      module Helpers
        class Appraisal
          include Constants

          attr_reader :id, :event, :domain, :primary, :secondary,
                      :emotional_outcome, :intensity, :coping_strategy,
                      :reappraised, :created_at, :reappraised_at

          def initialize(event:, primary:, secondary:, domain: nil)
            @id               = SecureRandom.uuid
            @event            = event
            @domain           = domain
            @primary          = normalize_dimensions(primary, PRIMARY_DIMENSIONS)
            @secondary        = normalize_dimensions(secondary, SECONDARY_DIMENSIONS)
            @intensity        = DEFAULT_INTENSITY
            @coping_strategy  = nil
            @reappraised      = false
            @created_at       = Time.now.utc
            @reappraised_at   = nil
            @emotional_outcome = compute_emotion
          end

          def reappraise(new_primary:, new_secondary:)
            @primary          = normalize_dimensions(new_primary, PRIMARY_DIMENSIONS)
            @secondary        = normalize_dimensions(new_secondary, SECONDARY_DIMENSIONS)
            @emotional_outcome = compute_emotion
            @intensity        = (@intensity * (1 - REAPPRAISAL_DISCOUNT)).clamp(INTENSITY_FLOOR, INTENSITY_CEILING)
            @reappraised      = true
            @reappraised_at   = Time.now.utc
            self
          end

          def compute_emotion
            relevance        = @primary[:relevance]
            goal_congruence  = @primary[:goal_congruence]
            coping_potential = @secondary[:coping_potential]

            return :indifference if relevance < 0.3

            classify_emotion(goal_congruence, coping_potential)
          end

          def to_h
            {
              id:                @id,
              event:             @event,
              domain:            @domain,
              primary:           @primary,
              secondary:         @secondary,
              emotional_outcome: @emotional_outcome,
              intensity:         @intensity,
              coping_strategy:   @coping_strategy,
              reappraised:       @reappraised,
              created_at:        @created_at,
              reappraised_at:    @reappraised_at
            }
          end

          def assign_coping(strategy_name)
            @coping_strategy = strategy_name
          end

          def decay!
            @intensity = (@intensity - DECAY_RATE).clamp(INTENSITY_FLOOR, INTENSITY_CEILING)
          end

          private

          def classify_emotion(goal_congruence, coping_potential)
            if goal_congruence < 0.4
              low_congruence_emotion(goal_congruence, coping_potential)
            elsif goal_congruence > 0.7
              :joy
            else
              :sadness
            end
          end

          def low_congruence_emotion(goal_congruence, coping_potential)
            if goal_congruence < 0.3
              :anger
            elsif coping_potential < 0.4
              :anxiety
            elsif coping_potential >= 0.6
              :challenge
            else
              :sadness
            end
          end

          def normalize_dimensions(raw, dimensions)
            dimensions.to_h do |dim|
              val = raw.fetch(dim, 0.0).to_f
              [dim, val.clamp(INTENSITY_FLOOR, INTENSITY_CEILING)]
            end
          end
        end
      end
    end
  end
end
