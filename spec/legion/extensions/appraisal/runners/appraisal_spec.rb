# frozen_string_literal: true

require 'legion/extensions/appraisal/client'

RSpec.describe Legion::Extensions::Appraisal::Runners::Appraisal do
  let(:client) { Legion::Extensions::Appraisal::Client.new }

  let(:primary_joy)    { { relevance: 0.9, goal_congruence: 0.9, goal_importance: 0.8 } }
  let(:primary_threat) { { relevance: 0.9, goal_congruence: 0.3, goal_importance: 0.8 } }
  let(:secondary_low)  { { coping_potential: 0.2, control_expectation: 0.3, future_expectancy: 0.4 } }
  let(:secondary_high) { { coping_potential: 0.8, control_expectation: 0.7, future_expectancy: 0.6 } }

  describe '#appraise_event' do
    it 'returns success: true with an appraisal' do
      result = client.appraise_event(event: 'deadline', primary: primary_joy, secondary: secondary_high)
      expect(result[:success]).to be(true)
      expect(result[:appraisal]).to include(:id, :emotional_outcome)
    end

    it 'assigns emotional_outcome based on appraisal pattern' do
      result = client.appraise_event(event: 'win', primary: primary_joy, secondary: secondary_high)
      expect(result[:appraisal][:emotional_outcome]).to eq(:joy)
    end

    it 'accepts optional domain' do
      result = client.appraise_event(event: 'test', primary: primary_joy, secondary: secondary_high,
                                     domain: 'work')
      expect(result[:appraisal][:domain]).to eq('work')
    end
  end

  describe '#reappraise_event' do
    it 'updates existing appraisal' do
      appraisal_id = client.appraise_event(event: 'e', primary: primary_threat,
                                           secondary: secondary_low)[:appraisal][:id]
      result = client.reappraise_event(appraisal_id: appraisal_id, new_primary: primary_joy,
                                       new_secondary: secondary_high)
      expect(result[:success]).to be(true)
      expect(result[:appraisal][:reappraised]).to be(true)
    end

    it 'returns failure for unknown id' do
      result = client.reappraise_event(appraisal_id: 'unknown', new_primary: primary_joy,
                                       new_secondary: secondary_high)
      expect(result[:success]).to be(false)
      expect(result[:error]).to include('not found')
    end
  end

  describe '#select_coping_strategy' do
    it 'assigns a coping strategy to the appraisal' do
      appraisal_id = client.appraise_event(event: 'e', primary: primary_threat,
                                           secondary: secondary_low)[:appraisal][:id]
      result = client.select_coping_strategy(appraisal_id: appraisal_id, coping_type: :problem_focused)
      expect(result[:success]).to be(true)
      expect(result[:appraisal][:coping_strategy]).not_to be_nil
    end

    it 'returns failure for unknown appraisal' do
      result = client.select_coping_strategy(appraisal_id: 'unknown', coping_type: :problem_focused)
      expect(result[:success]).to be(false)
    end
  end

  describe '#add_coping_strategy' do
    it 'registers a strategy' do
      result = client.add_coping_strategy(name: 'journaling', coping_type: :emotion_focused,
                                          effectiveness: 0.75)
      expect(result[:success]).to be(true)
      expect(result[:name]).to eq('journaling')
    end
  end

  describe '#evaluate_coping' do
    it 'returns effectiveness for an appraisal with coping' do
      client.add_coping_strategy(name: 'breathing', coping_type: :emotion_focused, effectiveness: 0.8)
      appraisal_id = client.appraise_event(event: 'e', primary: primary_threat,
                                           secondary: secondary_low)[:appraisal][:id]
      client.select_coping_strategy(appraisal_id: appraisal_id, coping_type: :emotion_focused)
      result = client.evaluate_coping(appraisal_id: appraisal_id)
      expect(result[:success]).to be(true)
      expect(result[:effectiveness]).to be_a(Float)
    end
  end

  describe '#emotional_pattern' do
    it 'returns success with pattern hash' do
      client.appraise_event(event: 'a', primary: primary_joy, secondary: secondary_high)
      client.appraise_event(event: 'b', primary: primary_joy, secondary: secondary_high)
      result = client.emotional_pattern
      expect(result[:success]).to be(true)
      expect(result[:pattern]).to be_a(Hash)
      expect(result[:pattern][:joy]).to eq(2)
    end
  end

  describe '#update_appraisal' do
    it 'runs decay and returns success' do
      client.appraise_event(event: 'e', primary: primary_joy, secondary: secondary_high)
      result = client.update_appraisal
      expect(result[:success]).to be(true)
    end
  end

  describe '#appraisal_stats' do
    it 'returns stats hash with totals' do
      client.appraise_event(event: 'a', primary: primary_joy,    secondary: secondary_high)
      client.appraise_event(event: 'b', primary: primary_threat, secondary: secondary_low)
      result = client.appraisal_stats
      expect(result[:success]).to be(true)
      expect(result[:total]).to eq(2)
      expect(result[:unresolved]).to eq(2)
      expect(result[:history_size]).to be >= 2
    end
  end
end
