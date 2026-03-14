# frozen_string_literal: true

module Legion
  module Extensions
    module Appraisal
      module Helpers
        class AppraisalEngine
          include Constants

          def initialize
            @appraisals        = {}
            @coping_strategies = {}
            @history           = []
          end

          def appraise(event:, primary:, secondary:, domain: nil)
            record = Appraisal.new(event: event, primary: primary, secondary: secondary, domain: domain)
            prune_appraisals if @appraisals.size >= MAX_APPRAISALS
            @appraisals[record.id] = record
            archive(record)
            record
          end

          def reappraise(appraisal_id:, new_primary:, new_secondary:)
            record = @appraisals[appraisal_id]
            return nil unless record

            record.reappraise(new_primary: new_primary, new_secondary: new_secondary)
            archive(record)
            record
          end

          def select_coping(appraisal_id:, coping_type:)
            record = @appraisals[appraisal_id]
            return nil unless record

            strategy = find_best_strategy(coping_type)
            name = strategy ? strategy[:name] : coping_type.to_s
            record.assign_coping(name)
            record
          end

          def add_coping_strategy(name:, coping_type:, effectiveness:)
            return false if @coping_strategies.size >= MAX_COPING_STRATEGIES

            @coping_strategies[name] = {
              name:          name,
              coping_type:   coping_type,
              effectiveness: effectiveness.to_f.clamp(INTENSITY_FLOOR, INTENSITY_CEILING)
            }
            true
          end

          def evaluate_coping(appraisal_id:)
            record = @appraisals[appraisal_id]
            return { effectiveness: 0.0, resolved: false } unless record
            return { effectiveness: 0.0, resolved: false } unless record.coping_strategy

            strategy    = @coping_strategies[record.coping_strategy]
            base        = strategy ? strategy[:effectiveness] : DEFAULT_INTENSITY
            resolved    = record.intensity < 0.3
            {
              appraisal_id:  appraisal_id,
              coping:        record.coping_strategy,
              effectiveness: base,
              intensity:     record.intensity,
              resolved:      resolved
            }
          end

          def by_emotion(emotion:)
            @appraisals.values.select { |rec| rec.emotional_outcome == emotion }
          end

          def by_domain(domain:)
            @appraisals.values.select { |rec| rec.domain == domain }
          end

          def unresolved
            @appraisals.values.select { |rec| rec.coping_strategy.nil? }
          end

          def emotional_pattern
            counts = Hash.new(0)
            recent_appraisals.each { |rec| counts[rec.emotional_outcome] += 1 }
            counts.sort_by { |_, cnt| -cnt }.to_h
          end

          def decay_all
            @appraisals.each_value(&:decay!)
          end

          def to_h
            {
              appraisals:        @appraisals.transform_values(&:to_h),
              coping_strategies: @coping_strategies,
              history_size:      @history.size
            }
          end

          private

          def archive(record)
            @history << { id: record.id, emotion: record.emotional_outcome, at: Time.now.utc }
            @history.shift while @history.size > MAX_HISTORY
          end

          def prune_appraisals
            oldest_key = @appraisals.min_by { |_, rec| rec.created_at }&.first
            @appraisals.delete(oldest_key) if oldest_key
          end

          def find_best_strategy(coping_type)
            matches = @coping_strategies.values.select { |str| str[:coping_type] == coping_type }
            matches.max_by { |str| str[:effectiveness] }
          end

          def recent_appraisals
            @appraisals.values.last(50)
          end
        end
      end
    end
  end
end
