# frozen_string_literal: true

module Legion
  module Extensions
    module Appraisal
      module Helpers
        module Constants
          MAX_APPRAISALS = 200
          MAX_COPING_STRATEGIES = 50
          MAX_HISTORY         = 300

          DEFAULT_INTENSITY   = 0.5
          INTENSITY_FLOOR     = 0.0
          INTENSITY_CEILING   = 1.0

          DECAY_RATE = 0.02
          REAPPRAISAL_DISCOUNT = 0.3

          PRIMARY_DIMENSIONS = %i[relevance goal_congruence goal_importance].freeze

          SECONDARY_DIMENSIONS = %i[coping_potential control_expectation future_expectancy].freeze

          APPRAISAL_EMOTIONS = {
            threat_low_coping:   :anxiety,
            threat_high_coping:  :challenge,
            loss:                :sadness,
            goal_incongruent:    :anger,
            goal_congruent:      :joy,
            irrelevant:          :indifference,
            unexpected_positive: :surprise,
            moral_violation:     :disgust
          }.freeze

          COPING_TYPES = %i[problem_focused emotion_focused meaning_focused avoidant social_support].freeze
        end
      end
    end
  end
end
