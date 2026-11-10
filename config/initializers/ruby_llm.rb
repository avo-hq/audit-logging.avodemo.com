# Configure RubyLLM for avo-ai. Set the key of the provider AVO_AI_MODEL belongs to.
#
# The model catalog lives in RubyLLM's registry, database-backed: load it with `bin/rails ruby_llm:load_models`
# after install, and refresh it from the admin Models resource ("Refresh models").
RubyLLM.configure do |config|
  config.anthropic_api_key = ENV.fetch("ANTHROPIC_API_KEY", nil)
  config.openai_api_key = ENV.fetch("OPENAI_API_KEY", nil)
  config.default_model = ENV.fetch("AVO_AI_MODEL", "claude-sonnet-5-5")
end
