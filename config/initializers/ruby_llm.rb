# Configure RubyLLM for avo-ai. Set the key of the provider AVO_AI_MODEL belongs to.
#
# The model catalog lives in RubyLLM's registry, database-backed: load it with `bin/rails ruby_llm:load_models`
# after install, and refresh it from the admin Models resource ("Refresh models").
RubyLLM.configure do |config|
  # Without a key RubyLLM starts no chat at all, the tour's scripted one included (lib/fake_llm.rb).
  config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"].presence || "unset"
  config.openai_api_key = ENV.fetch("OPENAI_API_KEY", nil)
  config.default_model = ENV.fetch("AVO_AI_MODEL", "claude-sonnet-5-5")
end

# Set once the app's code can load, and again after each reload in development.
Rails.application.config.to_prepare do
  RubyLLM.config.faraday_adapter = FakeLlm::Adapter
  # A page says here when it joins a live stream and when it leaves: the tour's answer waits for a page to be on its
  # chat's (FakeLlm.wait_for_page).
  Turbo::StreamsChannel.after_subscribe { FakeLlm.joined(verified_stream_name_from_params, 1) }
  Turbo::StreamsChannel.after_unsubscribe { FakeLlm.joined(verified_stream_name_from_params, -1) }
end
