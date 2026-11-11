# Records Avo's lines with ElevenLabs, one clip a line, into public/tour. Run it after editing a `voice` in
# config/tour.yml. Only lines with no clip are sent, because a recording costs credits, and clips no line uses go.
#
#   ELEVENLABS_API_KEY=... bin/rails tour:voices
namespace :tour do
  desc "Record the guided tour's lines that have no clip yet (needs ELEVENLABS_API_KEY)"
  task voices: :environment do
    require "net/http"

    key = ENV["ELEVENLABS_API_KEY"].presence || abort("Set ELEVENLABS_API_KEY to record.")
    lines = Tour.new.spoken
    Tour::CLIPS.mkpath
    (Tour::CLIPS.glob("*.mp3") - lines.map { |line| Tour.clip(line) }).each(&:delete)

    uri = URI("https://api.elevenlabs.io/v1/text-to-dialogue?output_format=mp3_44100_64")
    record = ->(body) { Net::HTTP.post(uri, body.to_json, "xi-api-key" => key, "Content-Type" => "application/json") }
    earlier = []

    lines.reject { |line| Tour.clip(line).exist? }.each do |line|
      body = {inputs: [{text: line, voice_id: Tour::VOICE}], model_id: Tour::MODEL, seed: 20261111}
      # The requests before this one keep him sounding like one take across clips. ElevenLabs refuses them at times,
      # so the line is then recorded on its own.
      response = record.call(body.merge(previous_request_ids: earlier.last(3))) if earlier.any?
      response = record.call(body) unless response.is_a?(Net::HTTPSuccess)
      abort "ElevenLabs #{response.code}: #{response.body.to_s.first(300)}" unless response.is_a?(Net::HTTPSuccess)

      Tour.clip(line).binwrite(response.body)
      earlier.push(response["request-id"] || response["x-request-id"]).compact!
      puts "recorded #{Tour.clip(line).basename}  #{line.first(70)}"
    end
  end
end
