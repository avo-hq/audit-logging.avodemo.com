require "puma"

# A stand-in for Anthropic's Messages API, so the seed can hold a chat with no API key. It answers a scripted
# prompt with the tool call a model would make, and everything after it (the tool, the confirmation card, the
# write, its audit entry) runs through avo-ai as it does for a real model.
module FakeLlm
  MODEL = "claude-sonnet-5-5"

  module_function

  def serve(script)
    @script = script
    server = Puma::Server.new(method(:call).to_proc, nil, min_threads: 1, max_threads: 4, log_writer: Puma::LogWriter.null)
    port = server.add_tcp_listener("127.0.0.1", 0).addr[1]
    thread = server.run
    yield "http://127.0.0.1:#{port}"
  ensure
    server&.stop(true)
    thread&.join
  end

  def call(env)
    request = JSON.parse(env["rack.input"].read)
    reply = reply_to(request)
    request["stream"] ? [200, {"content-type" => "text/event-stream"}, [stream(reply)]] : [200, {"content-type" => "application/json"}, [message(reply).to_json]]
  end

  # The titler offers only the rename tool and wants the title as text. A turn that ends in a tool result gets the
  # closing sentence; one that opens on a scripted prompt gets that prompt's tool call.
  def reply_to(request)
    tools = Array(request["tools"]).map { _1["name"] }
    _prompt, entry = @script.find { |text, _| transcript(request).include?(text) }
    return {text: entry ? entry[:title] : "Catalog question"} if tools == ["rename_conversation"] || tools.empty?

    called = request["messages"].any? { |m| Array(m["content"]).any? { _1.is_a?(Hash) && _1["type"] == "tool_use" } }
    return {text: entry ? entry[:after] : "Done."} if called || entry.nil?

    {tool: entry[:tool], input: entry[:input]}
  end

  def transcript(request) = request["messages"].to_json + request["system"].to_json

  def blocks(reply)
    return [{type: "text", text: reply[:text]}] if reply[:text]

    [{type: "tool_use", id: "toolu_#{SecureRandom.hex(10)}", name: reply[:tool], input: reply[:input]}]
  end

  def message(reply)
    {id: "msg_#{SecureRandom.hex(10)}", type: "message", role: "assistant", model: MODEL, content: blocks(reply),
     stop_reason: reply[:tool] ? "tool_use" : "end_turn", stop_sequence: nil, usage: {input_tokens: 1200, output_tokens: 40}}
  end

  def stream(reply)
    start = message(reply).merge(content: [], stop_reason: nil)
    events = [["message_start", {type: "message_start", message: start}]]
    blocks(reply).each_with_index do |block, index|
      if block[:type] == "text"
        events << ["content_block_start", {type: "content_block_start", index: index, content_block: {type: "text", text: ""}}]
        events << ["content_block_delta", {type: "content_block_delta", index: index, delta: {type: "text_delta", text: block[:text]}}]
      else
        events << ["content_block_start", {type: "content_block_start", index: index, content_block: block.merge(input: {})}]
        events << ["content_block_delta", {type: "content_block_delta", index: index, delta: {type: "input_json_delta", partial_json: block[:input].to_json}}]
      end
      events << ["content_block_stop", {type: "content_block_stop", index: index}]
    end
    events << ["message_delta", {type: "message_delta", delta: {stop_reason: reply[:tool] ? "tool_use" : "end_turn", stop_sequence: nil}, usage: {output_tokens: 40}}]
    events << ["message_stop", {type: "message_stop"}]
    events.map { |name, data| "event: #{name}\ndata: #{data.to_json}\n\n" }.join
  end
end
