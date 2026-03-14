# frozen_string_literal: true

require 'legion/extensions/appraisal/version'
require 'legion/extensions/appraisal/helpers/constants'
require 'legion/extensions/appraisal/helpers/appraisal'
require 'legion/extensions/appraisal/helpers/appraisal_engine'
require 'legion/extensions/appraisal/runners/appraisal'

module Legion
  module Extensions
    module Appraisal
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
