# frozen_string_literal: true

class PluginStore
  @@store = {}

  def self.get(plugin_name, key)
    value = @@store[plugin_name][key]
    value&.with_indifferent_access
  end

  def self.set(plugin_name, key, value)
    @@store[plugin_name] ||= {}
    @@store[plugin_name][key] = value
  end

  def self.remove(plugin_name, key)
    @@store[plugin_name].delete(key)
  end
end
