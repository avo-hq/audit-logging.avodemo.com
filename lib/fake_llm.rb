require "puma"

# A stand-in for Anthropic's Messages API. It answers a scripted prompt with the tool call a model would make, and
# everything after it (the tool, the confirmation card, the write, its audit entry) runs through avo-ai as it does
# for a real model. The seed holds its chats through it, and the tour's question gets its answer without a wait.
module FakeLlm
  MODEL = "claude-sonnet-5-5"

  # What the guided tour types into the chat (config/tour.yml). A model needs a key and takes its time, so these
  # are answered here: with the tool call a model would make, then a sentence around what the tool returned.
  TOUR = {
    # One product, always: the tour goes on to restock the one named here, so "none are low" would strand it. One
    # in a warehouse, because the tour then shows the warehouse that restock changed, and a product may have none.
    "Which products are running low on stock?" => {
      tool: "active_record_query",
      input: {resource: "Product", fields: %w[name quantity], chip_fields: ["quantity"],
              association_filters: [{association: "warehouse", exists: true}],
              sort: {field: "quantity", direction: "asc"}, limit: 1},
      title: "Products low on stock",
      after: ->(request) do
        row = FakeLlm.tool_result(request).fetch("rows").first
        "Lowest on stock in your warehouses right now:\n\n[#{row["name"]}](#{row["reference"]})"
      end
    },
    # "This product" is the one the chat named last. avo-ai shows the run as a card for the visitor to approve.
    "Restock this product" => {
      tool: "run_action",
      input: ->(request) do
        id = FakeLlm.named_product(request).to_s[/Product\/(\w+)/, 1]
        id && {operation: "run", resource: "Product", action: "Avo::Actions::Restock", record_ids: [id],
               fields: [{field: "units", value: 25}]}
      end,
      title: "Restock",
      # Only reached when the run was refused: one that ran ends on its card, with no word from the model after it.
      after: ->(request) { "That did not work: #{FakeLlm.tool_result(request)["error"]}" }
    }
  }.freeze

  # RubyLLM sends its requests through this (config/initializers/ruby_llm.rb). The turn the tour's question opens is
  # answered in process. Every other request goes out as it would without it.
  class Adapter < Faraday::Adapter
    def initialize(app = nil, options = {}, &block)
      super
      @http = Faraday::Adapter::NetHttp.new(app, options, &block)
    end

    def call(env)
      request = FakeLlm.asked(env)
      return @http.call(env) unless request

      super
      reply = FakeLlm.reply_to(request, TOUR)
      # A chat's turn and its titler ask at the same moment. A model answers them seconds apart. Answered at once,
      # the two jobs write at the same instant and SQLite fails one of them, so the title waits out the turn.
      if Array(request["tools"]).many?
        FakeLlm.wait_for_page(request) if request["messages"].one?
      else
        sleep 3
      end
      if request["stream"]
        # The status comes first, as from a server: RubyLLM reads it to tell a reply's chunks from an error's.
        save_response(env, 200, nil, {"content-type" => "text/event-stream"}, finished: false)
        env.stream_response { |&on_data| on_data.call(FakeLlm.stream(reply)) }
      else
        save_response(env, 200, FakeLlm.message(reply).to_json, {"content-type" => "application/json"}, finished: false)
      end
      env.response.finish(env)
      @app.call(env)
    end
  end

  # How many pages are on each live stream right now, by the stream's name (config/initializers/ruby_llm.rb counts).
  JOINED = Concurrent::Map.new

  module_function

  # The request cut down to its current turn, when one of the tour's prompts opened that turn. The turns before it
  # are kept aside as "earlier", and a later question in the same chat is the real model's to answer.
  def asked(env)
    request = JSON.parse(env.request_body.to_s)
    messages = Array(request["messages"])
    opening = messages.rindex { _1["role"] == "user" && text_in(_1).present? }
    return unless opening && prompt_in(messages[opening])

    request.merge("messages" => messages.drop(opening), "earlier" => messages.take(opening))
  rescue JSON::ParserError
    nil
  end

  def text_in(message)
    Array.wrap(message["content"]).filter_map { |block| block.is_a?(Hash) ? block["text"] : block }.join(" ")
  end

  def prompt_in(message) = TOUR.keys.find { text_in(message).include?(_1) }

  # The last product the chat named, as the link it was named with: "[Dell XPS 13](avo:Product/12?fields=quantity)".
  def named_product(request)
    request.fetch("earlier").map { text_in(_1) }.join("\n").scan(/\[[^\]]+\]\(avo:Product\/[^)]+\)/).last
  end

  def tool_result(request)
    blocks = request["messages"].flat_map { |message| Array(message["content"]).grep(Hash) }
    result = blocks.reverse.find { _1["type"] == "tool_result" }.fetch("content")
    JSON.parse(result.is_a?(Array) ? result.filter_map { _1["text"] }.join : result)
  end

  # avo-ai sends an answer to the chat's own live stream, which a page joins only once the chat exists. A model's
  # seconds cover that gap. A turn's first reply from here would be out before that, and never shown, so it waits up
  # to two seconds for the page.
  def wait_for_page(request)
    asked = Avo::Ai::Message.where(role: "user").where("content LIKE ?", "%#{prompt_in(request["messages"].first)}%")
    chat = asked.order(:id).last&.chat
    20.times { on_stream?(chat) ? break : sleep(0.1) } if chat
  end

  def joined(stream, by) = JOINED.compute(stream) { |pages| pages.to_i + by }

  # A page that opens the chat again joins its stream anew, so a page that was on it a minute ago does not count.
  def on_stream?(chat) = JOINED.each_pair.any? { |stream, pages| pages.positive? && stream.include?(chat.to_gid_param) }

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
  def reply_to(request, script = @script)
    tools = Array(request["tools"]).map { _1["name"] }
    _prompt, entry = script.find { |text, _| transcript(request).include?(text) }
    return {text: entry ? entry[:title] : "Catalog question"} if tools == ["rename_conversation"] || tools.empty?

    blocks = request["messages"].flat_map { |message| Array(message["content"]).grep(Hash) }
    called = blocks.any? { _1["type"] == "tool_use" }
    return {text: entry ? written(entry[:after], request) : "Done."} if called || entry.nil?

    input = written(entry[:input], request)
    input ? {tool: entry[:tool], input: input} : {text: "Which product do you mean?"}
  end

  # A tool's input and a closing sentence are given as they are, or as a block that writes them from the request.
  def written(part, request) = part.respond_to?(:call) ? part.call(request) : part

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
