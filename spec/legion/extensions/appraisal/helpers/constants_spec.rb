# frozen_string_literal: true

RSpec.describe Legion::Extensions::Appraisal::Helpers::Constants do
  let(:mod) { described_class }

  it 'defines MAX_APPRAISALS' do
    expect(mod::MAX_APPRAISALS).to eq(200)
  end

  it 'defines MAX_COPING_STRATEGIES' do
    expect(mod::MAX_COPING_STRATEGIES).to eq(50)
  end

  it 'defines MAX_HISTORY' do
    expect(mod::MAX_HISTORY).to eq(300)
  end

  it 'defines intensity bounds' do
    expect(mod::INTENSITY_FLOOR).to eq(0.0)
    expect(mod::INTENSITY_CEILING).to eq(1.0)
    expect(mod::DEFAULT_INTENSITY).to eq(0.5)
  end

  it 'defines DECAY_RATE' do
    expect(mod::DECAY_RATE).to eq(0.02)
  end

  it 'defines REAPPRAISAL_DISCOUNT' do
    expect(mod::REAPPRAISAL_DISCOUNT).to eq(0.3)
  end

  it 'defines PRIMARY_DIMENSIONS' do
    expect(mod::PRIMARY_DIMENSIONS).to contain_exactly(:relevance, :goal_congruence, :goal_importance)
  end

  it 'defines SECONDARY_DIMENSIONS' do
    expect(mod::SECONDARY_DIMENSIONS).to contain_exactly(:coping_potential, :control_expectation, :future_expectancy)
  end

  it 'maps APPRAISAL_EMOTIONS' do
    expect(mod::APPRAISAL_EMOTIONS[:threat_low_coping]).to eq(:anxiety)
    expect(mod::APPRAISAL_EMOTIONS[:goal_congruent]).to eq(:joy)
    expect(mod::APPRAISAL_EMOTIONS[:irrelevant]).to eq(:indifference)
  end

  it 'defines COPING_TYPES' do
    expect(mod::COPING_TYPES).to include(:problem_focused, :emotion_focused, :meaning_focused)
  end
end
