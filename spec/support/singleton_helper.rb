# frozen_string_literal: true

# Clears cached Singleton instances so each example starts from a clean state.
module SingletonHelper
  def reset_singleton!(klass)
    klass.instance_variable_set(:@singleton__instance__, nil)
  end
end
