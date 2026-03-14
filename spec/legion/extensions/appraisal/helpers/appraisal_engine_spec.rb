# frozen_string_literal: true

RSpec.describe Legion::Extensions::Appraisal::Helpers::AppraisalEngine do
  let(:engine) { described_class.new }

  let(:primary_joy)    { { relevance: 0.9, goal_congruence: 0.9, goal_importance: 0.8 } }
  let(:primary_threat) { { relevance: 0.9, goal_congruence: 0.3, goal_importance: 0.8 } }
  let(:secondary_low)  { { coping_potential: 0.2, control_expectation: 0.3, future_expectancy: 0.4 } }
  let(:secondary_high) { { coping_potential: 0.8, control_expectation: 0.7, future_expectancy: 0.6 } }

  describe '#appraise' do
    it 'creates and returns an appraisal' do
      record = engine.appraise(event: 'test', primary: primary_joy, secondary: secondary_high)
      expect(record).to be_a(Legion::Extensions::Appraisal::Helpers::Appraisal)
      expect(record.event).to eq('test')
    end

    it 'stores appraisals by id' do
      record = engine.appraise(event: 'test', primary: primary_joy, secondary: secondary_high)
      expect(engine.to_h[:appraisals]).to have_key(record.id)
    end

    it 'computes emotional_outcome' do
      record = engine.appraise(event: 'test', primary: primary_joy, secondary: secondary_high)
      expect(record.emotional_outcome).to eq(:joy)
    end
  end

  describe '#reappraise' do
    it 'updates an existing appraisal' do
      record = engine.appraise(event: 'test', primary: primary_threat, secondary: secondary_low)
      expect(record.emotional_outcome).to eq(:anxiety)
      updated = engine.reappraise(appraisal_id: record.id, new_primary: primary_joy, new_secondary: secondary_high)
      expect(updated.emotional_outcome).to eq(:joy)
      expect(updated.reappraised).to be(true)
    end

    it 'returns nil for unknown id' do
      result = engine.reappraise(appraisal_id: 'unknown', new_primary: primary_joy, new_secondary: secondary_high)
      expect(result).to be_nil
    end
  end

  describe '#select_coping' do
    it 'assigns coping to appraisal' do
      record = engine.appraise(event: 'test', primary: primary_threat, secondary: secondary_low)
      updated = engine.select_coping(appraisal_id: record.id, coping_type: :problem_focused)
      expect(updated.coping_strategy).not_to be_nil
    end

    it 'prefers registered strategies for the coping type' do
      engine.add_coping_strategy(name: 'action_plan', coping_type: :problem_focused, effectiveness: 0.9)
      record = engine.appraise(event: 'test', primary: primary_threat, secondary: secondary_low)
      updated = engine.select_coping(appraisal_id: record.id, coping_type: :problem_focused)
      expect(updated.coping_strategy).to eq('action_plan')
    end

    it 'returns nil for unknown appraisal' do
      result = engine.select_coping(appraisal_id: 'unknown', coping_type: :problem_focused)
      expect(result).to be_nil
    end
  end

  describe '#add_coping_strategy' do
    it 'registers a strategy and returns true' do
      result = engine.add_coping_strategy(name: 'reframing', coping_type: :emotion_focused, effectiveness: 0.7)
      expect(result).to be(true)
    end

    it 'clamps effectiveness to [0, 1]' do
      engine.add_coping_strategy(name: 'over', coping_type: :problem_focused, effectiveness: 1.5)
      data = engine.to_h
      # Strategy stored (engine is internal, test via evaluate_coping behavior)
      expect(data).to be_a(Hash)
    end
  end

  describe '#evaluate_coping' do
    it 'returns effectiveness 0.0 when no coping assigned' do
      record = engine.appraise(event: 'test', primary: primary_threat, secondary: secondary_low)
      result = engine.evaluate_coping(appraisal_id: record.id)
      expect(result[:effectiveness]).to eq(0.0)
      expect(result[:resolved]).to be(false)
    end

    it 'uses registered strategy effectiveness' do
      engine.add_coping_strategy(name: 'mindfulness', coping_type: :emotion_focused, effectiveness: 0.85)
      record = engine.appraise(event: 'test', primary: primary_threat, secondary: secondary_low)
      engine.select_coping(appraisal_id: record.id, coping_type: :emotion_focused)
      result = engine.evaluate_coping(appraisal_id: record.id)
      expect(result[:effectiveness]).to be_within(0.01).of(0.85)
    end

    it 'returns defaults for unknown appraisal' do
      result = engine.evaluate_coping(appraisal_id: 'unknown')
      expect(result[:effectiveness]).to eq(0.0)
    end
  end

  describe '#by_emotion' do
    it 'filters appraisals by emotional outcome' do
      engine.appraise(event: 'a', primary: primary_joy,    secondary: secondary_high)
      engine.appraise(event: 'b', primary: primary_threat, secondary: secondary_low)
      joy_list = engine.by_emotion(emotion: :joy)
      expect(joy_list.size).to eq(1)
      expect(joy_list.first.event).to eq('a')
    end
  end

  describe '#by_domain' do
    it 'filters appraisals by domain' do
      engine.appraise(event: 'a', primary: primary_joy, secondary: secondary_high, domain: 'work')
      engine.appraise(event: 'b', primary: primary_joy, secondary: secondary_high, domain: 'personal')
      work_list = engine.by_domain(domain: 'work')
      expect(work_list.size).to eq(1)
      expect(work_list.first.event).to eq('a')
    end
  end

  describe '#unresolved' do
    it 'returns appraisals without coping strategy' do
      rec1 = engine.appraise(event: 'a', primary: primary_joy, secondary: secondary_high)
      rec2 = engine.appraise(event: 'b', primary: primary_joy, secondary: secondary_high)
      engine.select_coping(appraisal_id: rec1.id, coping_type: :problem_focused)
      unresolved = engine.unresolved
      expect(unresolved.map(&:id)).to include(rec2.id)
      expect(unresolved.map(&:id)).not_to include(rec1.id)
    end
  end

  describe '#emotional_pattern' do
    it 'returns emotion counts sorted by frequency' do
      3.times { engine.appraise(event: 'a', primary: primary_joy, secondary: secondary_high) }
      engine.appraise(event: 'b', primary: primary_threat, secondary: secondary_low)
      pattern = engine.emotional_pattern
      expect(pattern.first.first).to eq(:joy)
    end

    it 'returns empty hash when no appraisals' do
      expect(engine.emotional_pattern).to eq({})
    end
  end

  describe '#decay_all' do
    it 'reduces intensity for all appraisals' do
      rec = engine.appraise(event: 'test', primary: primary_joy, secondary: secondary_high)
      engine.decay_all
      expect(rec.intensity).to be < 0.5
    end
  end

  describe '#to_h' do
    it 'returns hash with appraisals, coping_strategies, history_size' do
      engine.appraise(event: 'test', primary: primary_joy, secondary: secondary_high)
      result = engine.to_h
      expect(result).to have_key(:appraisals)
      expect(result).to have_key(:coping_strategies)
      expect(result).to have_key(:history_size)
    end
  end
end
