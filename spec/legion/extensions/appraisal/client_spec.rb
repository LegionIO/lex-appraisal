# frozen_string_literal: true

require 'legion/extensions/appraisal/client'

RSpec.describe Legion::Extensions::Appraisal::Client do
  let(:client) { described_class.new }

  it 'responds to all runner methods' do
    expect(client).to respond_to(:appraise_event)
    expect(client).to respond_to(:reappraise_event)
    expect(client).to respond_to(:select_coping_strategy)
    expect(client).to respond_to(:add_coping_strategy)
    expect(client).to respond_to(:evaluate_coping)
    expect(client).to respond_to(:emotional_pattern)
    expect(client).to respond_to(:update_appraisal)
    expect(client).to respond_to(:appraisal_stats)
  end

  it 'maintains isolated engine state per client instance' do
    client2 = described_class.new
    client.appraise_event(
      event:     'only in client1',
      primary:   { relevance: 0.9, goal_congruence: 0.9, goal_importance: 0.8 },
      secondary: { coping_potential: 0.8, control_expectation: 0.7, future_expectancy: 0.6 }
    )
    expect(client.appraisal_stats[:total]).to eq(1)
    expect(client2.appraisal_stats[:total]).to eq(0)
  end

  it 'runs a full appraisal cycle' do
    primary   = { relevance: 0.9, goal_congruence: 0.3, goal_importance: 0.8 }
    secondary = { coping_potential: 0.2, control_expectation: 0.3, future_expectancy: 0.4 }

    appraisal_id = client.appraise_event(event: 'crisis', primary: primary,
                                         secondary: secondary)[:appraisal][:id]
    client.add_coping_strategy(name: 'deep_breathing', coping_type: :emotion_focused, effectiveness: 0.7)
    client.select_coping_strategy(appraisal_id: appraisal_id, coping_type: :emotion_focused)
    eval_result = client.evaluate_coping(appraisal_id: appraisal_id)
    expect(eval_result[:success]).to be(true)
    expect(eval_result[:coping]).to eq('deep_breathing')

    client.reappraise_event(
      appraisal_id:  appraisal_id,
      new_primary:   { relevance: 0.9, goal_congruence: 0.9, goal_importance: 0.8 },
      new_secondary: { coping_potential: 0.8, control_expectation: 0.7, future_expectancy: 0.6 }
    )
    client.update_appraisal
    stats = client.appraisal_stats
    expect(stats[:total]).to eq(1)
    expect(stats[:pattern]).to be_a(Hash)
  end
end
