# frozen_string_literal: true

require 'legion/extensions/appraisal/helpers/constants'
require 'legion/extensions/appraisal/helpers/appraisal'
require 'legion/extensions/appraisal/helpers/appraisal_engine'
require 'legion/extensions/appraisal/runners/appraisal'

module Legion
  module Extensions
    module Appraisal
      class Client
        include Runners::Appraisal
      end
    end
  end
end
