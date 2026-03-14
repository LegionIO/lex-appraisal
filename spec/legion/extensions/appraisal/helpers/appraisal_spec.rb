# frozen_string_literal: true

RSpec.describe Legion::Extensions::Appraisal::Helpers::Appraisal do
  let(:primary_low)  { { relevance: 0.2, goal_congruence: 0.2, goal_importance: 0.5 } }
  let(:primary_high) { { relevance: 0.8, goal_congruence: 0.8, goal_importance: 0.9 } }
  let(:secondary_low)  { { coping_potential: 0.2, control_expectation: 0.3, future_expectancy: 0.4 } }
  let(:secondary_high) { { coping_potential: 0.8, control_expectation: 0.7, future_expectancy: 0.6 } }

  def build(primary: primary_high, secondary: secondary_high, domain: 'work')
    described_class.new(event: 'test event', primary: primary, secondary: secondary, domain: domain)
  end

  describe '#initialize' do
    it 'sets id, event, domain' do
      appraisal = build
      expect(appraisal.id).to be_a(String)
      expect(appraisal.event).to eq('test event')
      expect(appraisal.domain).to eq('work')
    end

    it 'normalizes primary dimensions' do
      appraisal = build
      expect(appraisal.primary.keys).to contain_exactly(:relevance, :goal_congruence, :goal_importance)
    end

    it 'normalizes secondary dimensions' do
      appraisal = build
      expect(appraisal.secondary.keys).to contain_exactly(:coping_potential, :control_expectation, :future_expectancy)
    end

    it 'clamps out-of-range values' do
      appraisal = described_class.new(
        event:     'e',
        primary:   { relevance: 2.0, goal_congruence: -0.5, goal_importance: 0.5 },
        secondary: secondary_high
      )
      expect(appraisal.primary[:relevance]).to eq(1.0)
      expect(appraisal.primary[:goal_congruence]).to eq(0.0)
    end

    it 'sets default intensity' do
      expect(build.intensity).to eq(0.5)
    end

    it 'sets reappraised to false' do
      expect(build.reappraised).to be(false)
    end
  end

  describe '#compute_emotion' do
    it 'returns :indifference when relevance is low' do
      appraisal = described_class.new(
        event:     'e',
        primary:   { relevance: 0.2, goal_congruence: 0.5, goal_importance: 0.5 },
        secondary: secondary_high
      )
      expect(appraisal.emotional_outcome).to eq(:indifference)
    end

    it 'returns :anxiety for threat with low coping' do
      appraisal = described_class.new(
        event:     'e',
        primary:   { relevance: 0.9, goal_congruence: 0.3, goal_importance: 0.8 },
        secondary: { coping_potential: 0.2, control_expectation: 0.3, future_expectancy: 0.4 }
      )
      expect(appraisal.emotional_outcome).to eq(:anxiety)
    end

    it 'returns :challenge for threat with high coping' do
      appraisal = described_class.new(
        event:     'e',
        primary:   { relevance: 0.9, goal_congruence: 0.3, goal_importance: 0.8 },
        secondary: { coping_potential: 0.8, control_expectation: 0.7, future_expectancy: 0.6 }
      )
      expect(appraisal.emotional_outcome).to eq(:challenge)
    end

    it 'returns :anger for very low goal_congruence' do
      appraisal = described_class.new(
        event:     'e',
        primary:   { relevance: 0.9, goal_congruence: 0.2, goal_importance: 0.8 },
        secondary: { coping_potential: 0.5, control_expectation: 0.5, future_expectancy: 0.5 }
      )
      expect(appraisal.emotional_outcome).to eq(:anger)
    end

    it 'returns :joy for high goal_congruence' do
      appraisal = described_class.new(
        event:     'e',
        primary:   { relevance: 0.9, goal_congruence: 0.9, goal_importance: 0.8 },
        secondary: secondary_high
      )
      expect(appraisal.emotional_outcome).to eq(:joy)
    end

    it 'returns :sadness as fallback' do
      appraisal = described_class.new(
        event:     'e',
        primary:   { relevance: 0.9, goal_congruence: 0.5, goal_importance: 0.5 },
        secondary: { coping_potential: 0.5, control_expectation: 0.5, future_expectancy: 0.5 }
      )
      expect(appraisal.emotional_outcome).to eq(:sadness)
    end
  end

  describe '#reappraise' do
    it 'updates emotion and reduces intensity' do
      appraisal = described_class.new(
        event: 'e', primary: primary_low, secondary: secondary_low
      )
      original_intensity = appraisal.intensity
      appraisal.reappraise(new_primary: primary_high, new_secondary: secondary_high)
      expect(appraisal.reappraised).to be(true)
      expect(appraisal.intensity).to be < original_intensity
      expect(appraisal.reappraised_at).not_to be_nil
    end

    it 'recomputes emotional_outcome' do
      appraisal = described_class.new(
        event:     'e',
        primary:   { relevance: 0.2, goal_congruence: 0.5, goal_importance: 0.5 },
        secondary: secondary_high
      )
      expect(appraisal.emotional_outcome).to eq(:indifference)
      appraisal.reappraise(
        new_primary:   { relevance: 0.9, goal_congruence: 0.9, goal_importance: 0.8 },
        new_secondary: secondary_high
      )
      expect(appraisal.emotional_outcome).to eq(:joy)
    end

    it 'applies REAPPRAISAL_DISCOUNT to intensity' do
      appraisal = build
      appraisal.reappraise(new_primary: primary_high, new_secondary: secondary_high)
      expected = 0.5 * (1 - Legion::Extensions::Appraisal::Helpers::Constants::REAPPRAISAL_DISCOUNT)
      expect(appraisal.intensity).to be_within(0.001).of(expected)
    end
  end

  describe '#decay!' do
    it 'reduces intensity by DECAY_RATE' do
      appraisal = build
      appraisal.decay!
      expected = 0.5 - Legion::Extensions::Appraisal::Helpers::Constants::DECAY_RATE
      expect(appraisal.intensity).to be_within(0.001).of(expected)
    end

    it 'does not go below INTENSITY_FLOOR' do
      appraisal = described_class.new(
        event:     'e',
        primary:   { relevance: 0.9, goal_congruence: 0.9, goal_importance: 0.9 },
        secondary: secondary_high
      )
      60.times { appraisal.decay! }
      expect(appraisal.intensity).to eq(0.0)
    end
  end

  describe '#assign_coping' do
    it 'sets coping_strategy' do
      appraisal = build
      appraisal.assign_coping('reframing')
      expect(appraisal.coping_strategy).to eq('reframing')
    end
  end

  describe '#to_h' do
    it 'returns a hash with expected keys' do
      appraisal = build
      keys = appraisal.to_h.keys
      expect(keys).to include(:id, :event, :domain, :primary, :secondary, :emotional_outcome,
                              :intensity, :coping_strategy, :reappraised, :created_at, :reappraised_at)
    end
  end
end
